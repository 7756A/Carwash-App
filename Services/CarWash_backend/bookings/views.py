from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import get_object_or_404
import json

from .models import Booking
from .serializers import BookingCreateSerializer
from .payment_gateways.mpesa import lipa_na_mpesa
from .payment_gateways.paypal import initiate_paypal_payment
from .payment_gateways.visa import initiate_visa_payment
from Tenant.models import Tenant, CarWash, Service, Staff
from users.models import CustomUser

class TenantBookingList(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({"message": "Tenant booking list placeholder"})

class CreateBooking(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data.copy()
        user = request.user

        service_id = data.get('service')
        carwash_id = data.get('carwash')
        date = data.get('date')
        time_slot = data.get('time_slot')

        if not service_id or not carwash_id:
            return Response({'error': 'Service and carwash ID are required.'}, status=400)

        try:
            service = Service.objects.get(id=service_id)
            carwash = CarWash.objects.get(id=carwash_id)
            tenant = carwash.tenant
            amount = service.price
        except Service.DoesNotExist:
            return Response({'error': 'Service not found.'}, status=404)
        except CarWash.DoesNotExist:
            return Response({'error': 'Car wash not found.'}, status=404)

        # --- 1. Create booking immediately ---
        booking = Booking.objects.create(
            tenant=tenant,
            carwash=carwash,
            service=service,
            customer=user,
            customer_name=user.get_full_name() or user.username,
            phone_number=data.get("mpesa_number") or getattr(user, "phone_number", None),
            amount=amount,
            time_slot=time_slot,
            payment_method=data.get("payment_method"),
            status="pending",  # initial state
        )

        # Metadata for payment provider
        metadata = {
            "booking_id": booking.id,  # important for callback!
            "user_id": user.id,
            "service_id": service.id,
            "carwash_id": carwash.id,
            "tenant_id": tenant.id,
            "date": date,
            "time_slot": time_slot,
        }

        payment_method = data.get("payment_method")
        response = None

        if payment_method == "mpesa":
            phone_number = booking.phone_number
            if not phone_number:
                return Response({"error": "M-Pesa number required"}, status=400)

            # Initiate STK Push
            response = lipa_na_mpesa(amount, phone_number, metadata)

            # Save reference
            booking.payment_reference = response.get("CheckoutRequestID", "pending")
            booking.save()

        elif payment_method == "paypal":
            response = initiate_paypal_payment(amount, metadata)

        elif payment_method == "visa":
            response = initiate_visa_payment(amount, metadata)

        else:
            return Response({"error": "Unsupported payment method"}, status=400)

        if not response or "error" in response:
            booking.status = "failed"
            booking.save()
            return Response({"status": "payment_failed", "details": response}, status=400)

        return Response({
            "status": "payment_initiated",
            "payment_method": payment_method,
            "payment_response": response,
            "booking_id": booking.id,
        })



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
