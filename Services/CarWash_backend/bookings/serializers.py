from rest_framework import serializers
from .models import Booking
from users.models import CustomUser
from bookings.payment_gateways.mpesa import lipa_na_mpesa


class BookingCreateSerializer(serializers.ModelSerializer):
    mpesa_number = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = Booking
        fields = [
            'id',
            'carwash',
            'service',
            'time_slot',
            'payment_method',
            'mpesa_number'
        ]

    def validate(self, attrs):
        user = self.context.get("user")

        # Ensure M-Pesa number is available from profile or input
        if attrs.get('payment_method') == 'mpesa':
            phone_number = getattr(user, "phone_number", None) or attrs.get('mpesa_number')
            if not phone_number:
                raise serializers.ValidationError({
                    "mpesa_number": "Phone number is required for M-Pesa payments."
                })
        return attrs

    def create(self, validated_data):
        user = validated_data.pop("user")   # we inject this in the view
        carwash = validated_data['carwash']
        service = validated_data['service']
        tenant = carwash.tenant

        mpesa_number = validated_data.pop('mpesa_number', None)
        phone_number = getattr(user, "phone_number", None) or mpesa_number

        booking = Booking.objects.create(
            tenant=tenant,
            carwash=carwash,
            service=service,
            customer=user,
            customer_name=user.get_full_name() or user.username,
            phone_number=phone_number,
            amount=service.price,
            time_slot=validated_data['time_slot'],
            payment_method=validated_data.get('payment_method'),
        )

        # M-Pesa STK Push
        if booking.payment_method == 'mpesa' and phone_number:
            try:
                response = lipa_na_mpesa(
                    booking.amount,
                    phone_number,
                    {
                        "user_id": user.id,
                        "service_id": service.id,
                        "carwash_id": carwash.id,
                        "tenant_id": tenant.id,
                        "time_slot": booking.time_slot.isoformat(),
                    }
                )
                booking.payment_reference = response.get("CheckoutRequestID", "Pending")
                booking.save()
            except Exception as e:
                raise serializers.ValidationError({"mpesa": f"STK push failed: {str(e)}"})

        return booking
    


class BookingListSerializer(serializers.ModelSerializer):
    carwash_name = serializers.CharField(source="carwash.name", read_only=True)
    service_name = serializers.CharField(source="service.name", read_only=True)

    class Meta:
        model = Booking
        fields = [
            "id",
            "carwash_name",
            "service_name",
            "time_slot",
            "amount",
            "status",
            "created_at",
        ]