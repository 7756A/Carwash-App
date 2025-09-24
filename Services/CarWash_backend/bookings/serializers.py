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
        request = self.context.get('request')
        user = request.user

        # Ensure M-Pesa number is available from profile or input
        if attrs.get('payment_method') == 'mpesa':
            phone_number = user.phone_number or attrs.get('mpesa_number')
            if not phone_number:
                raise serializers.ValidationError({
                    "mpesa_number": "Phone number is required for M-Pesa payments."
                })
        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        carwash = validated_data['carwash']
        service = validated_data['service']
        tenant = carwash.tenant

        mpesa_number = validated_data.pop('mpesa_number', None)
        phone_number = user.phone_number or mpesa_number

        booking = Booking.objects.create(
            tenant=tenant,
            carwash=carwash,
            service=service,
            customer=user,
            customer_name=user.get_full_name() or user.username,  # snapshot at time of booking
            phone_number=phone_number,
            amount=service.price,
            time_slot=validated_data['time_slot'],
            payment_method=validated_data.get('payment_method'),
        )

        # M-Pesa STK Push (only if M-Pesa is selected)
        if booking.payment_method == 'mpesa' and phone_number:
            try:
                from bookings.payment_gateways.mpesa import lipa_na_mpesa
                response = lipa_na_mpesa(booking)
                booking.payment_reference = response.get("CheckoutRequestID", "Pending")
                booking.save()
            except Exception as e:
                raise serializers.ValidationError({"mpesa": f"STK push failed: {str(e)}"})

        return booking
