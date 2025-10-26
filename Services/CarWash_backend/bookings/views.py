from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import get_object_or_404
import json
from .serializers import BookingCreateSerializer, BookingListSerializer
from .models import Booking
from .serializers import BookingCreateSerializer
from .payment_gateways.mpesa import lipa_na_mpesa
from .payment_gateways.paypal import initiate_paypal_payment
from .payment_gateways.visa import initiate_visa_payment
from Tenant.models import Tenant, CarWash, Service, Staff
from users.models import CustomUser
from datetime import datetime

class TenantBookingList(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({"message": "Tenant booking list placeholder"})

class CreateBooking(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data.copy()
        user = request.user

        # --- Services ---
        service_ids = data.get("services") or data.get("service_ids")
        carwash_id = data.get("carwash")
        date = data.get("date")
        time_slot = data.get("time_slot")  # Expecting "YYYY-MM-DD HH:MM"

        if not service_ids or not carwash_id:
            return Response({'error': 'Services and carwash ID are required.'}, status=400)

        # Normalize service_ids to a list
        if isinstance(service_ids, int):
            service_ids = [service_ids]
        elif isinstance(service_ids, str):
            try:
                import json
                service_ids = json.loads(service_ids)
            except Exception:
                service_ids = [int(service_ids)]

        # Validate carwash
        try:
            carwash = CarWash.objects.get(id=carwash_id)
            tenant = carwash.tenant
        except CarWash.DoesNotExist:
            return Response({'error': 'Car wash not found.'}, status=404)

        # Get service objects
        services = Service.objects.filter(id__in=service_ids)
        if not services.exists():
            return Response({'error': 'No valid services found.'}, status=404)

        # Validate and parse datetime
        try:
            booking_datetime = datetime.strptime(time_slot, "%Y-%m-%d %H:%M")
        except ValueError:
            return Response({'error': 'Time slot must be in YYYY-MM-DD HH:MM format.'}, status=400)

        # Calculate total amount
        total_amount = sum(s.price for s in services)

        # --- Create bookings ---
        bookings = []
        for service in services:
            booking = Booking.objects.create(
                tenant=tenant,
                carwash=carwash,
                service=service,
                customer=user,
                customer_name=user.get_full_name() or user.username,
                phone_number=data.get("mpesa_number") or getattr(user, "phone_number", None),
                amount=service.price,
                time_slot=booking_datetime,
                payment_method=data.get("payment_method"),
                status="pending",
            )
            bookings.append(booking)

        # Payment metadata
        metadata = {
            "booking_ids": [b.id for b in bookings],
            "user_id": user.id,
            "service_ids": service_ids,
            "carwash_id": carwash.id,
            "tenant_id": tenant.id,
            "datetime": booking_datetime.isoformat(),
        }

        payment_method = data.get("payment_method")
        response = None

        # --- Payment ---
        if payment_method == "mpesa":
            phone_number = bookings[0].phone_number
            if not phone_number:
                return Response({"error": "M-Pesa number required"}, status=400)

            response = lipa_na_mpesa(total_amount, phone_number, metadata)
            ref = response.get("CheckoutRequestID", "pending")
            for booking in bookings:
                booking.payment_reference = ref
                booking.save()

        elif payment_method == "paypal":
            response = initiate_paypal_payment(total_amount, metadata)

        elif payment_method == "visa":
            response = initiate_visa_payment(total_amount, metadata)

        else:
            return Response({"error": "Unsupported payment method"}, status=400)

        # --- Payment failure handling ---
        if not response or "error" in response:
            for booking in bookings:
                booking.status = "failed"
                booking.save()
            return Response({"status": "payment_failed", "details": response}, status=400)

        return Response({
            "status": "payment_initiated",
            "payment_method": payment_method,
            "total_amount": total_amount,
            "payment_response": response,
            "booking_ids": [b.id for b in bookings],
        })


class CustomerBookingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        bookings = Booking.objects.filter(customer=user).order_by("-created_at")
        serializer = BookingListSerializer(bookings, many=True)
        return Response(serializer.data)



@csrf_exempt
def mpesa_callback(request):
    data = json.loads(request.body.decode("utf-8"))
    result_code = data["Body"]["stkCallback"]["ResultCode"]
    checkout_id = data["Body"]["stkCallback"]["CheckoutRequestID"]

    try:
        booking = Booking.objects.get(payment_reference=checkout_id)
    except Booking.DoesNotExist:
        return JsonResponse({"error": "Booking not found"}, status=404)

    if result_code == 0:  # success
        booking.status = "confirmed"
    else:
        booking.status = "failed"
    booking.save()

    return JsonResponse({"message": "Callback processed successfully"})
