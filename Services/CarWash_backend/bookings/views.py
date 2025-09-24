from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.db.models import Q
from .models import Booking
from .serializers import BookingCreateSerializer
from .payment_gateways.mpesa import lipa_na_mpesa
from .payment_gateways.paypal import initiate_paypal_payment
from .payment_gateways.visa import initiate_visa_payment
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import get_object_or_404
import json
from Tenant.models import Tenant, CarWash, Service
from users.models import CustomUser


class TenantBookingList(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        tenant_id = request.query_params.get('tenantId')
        staff = request.query_params.get('staff')
        start = request.query_params.get('start')
        end = request.query_params.get('end')

        if not tenant_id:
            return Response({"error": "tenantId query parameter is required"}, status=400)

        bookings = Booking.objects.filter(tenant_id=tenant_id)

        if staff:
            bookings = bookings.filter(staff_id=staff)
        if start and end:
            bookings = bookings.filter(time_slot__range=[start, end])

        serializer = BookingCreateSerializer(bookings, many=True)
        return Response(serializer.data)


# Calendar view: aggregate bookings by staff and date
class CalendarBookingView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        tenant_id = request.query_params.get('tenantId')
        if not tenant_id:
            return Response({"error": "tenantId query parameter is required"}, status=400)

        bookings = Booking.objects.filter(tenant_id=tenant_id)
        data = {}
        for booking in bookings:
            key = f"{booking.staff_id}_{booking.time_slot.date()}"
            if key not in data:
                data[key] = []
            data[key].append(BookingCreateSerializer(booking).data)
        return Response(data)




class NearbyCarWashesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Optionally filter by location
        carwashes = CarWash.objects.all()
        serializer = CarWashSerializer(carwashes, many=True)
        return Response(serializer.data)


# Check staff availability for a given date
class StaffAvailability(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        tenant_id = request.query_params.get('tenantId')
        service_id = request.query_params.get('serviceId')
        date = request.query_params.get('date')  # YYYY-MM-DD

        if not all([tenant_id, service_id, date]):
            return Response({"error": "tenantId, serviceId, and date are required"}, status=400)

        try:
            service = Service.objects.get(id=service_id, tenant_id=tenant_id)
        except Service.DoesNotExist:
            return Response({"error": "Service not found for tenant"}, status=404)

        slots = []
        active_staff = Staff.objects.filter(tenant_id=tenant_id, is_active=True)
        for staff in active_staff:
            for hour in range(9, 17):
                time_str = f"{date}T{hour:02}:00:00"
                exists = Booking.objects.filter(staff=staff, time_slot=time_str).exists()
                if not exists:
                    slots.append({
                        "staff_id": staff.id,
                        "staff_name": staff.name,
                        "time": time_str,
                    })

        return Response(slots)



class ServiceListByCarWash(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        carwash_id = request.query_params.get('carwashId')
        if not carwash_id:
            return Response({"error": "carwashId query parameter is required"}, status=status.HTTP_400_BAD_REQUEST)

        services = Service.objects.filter(carwash_id=carwash_id)
        serializer = ServiceSerializer(services, many=True)
        return Response(serializer.data)

class CreateBooking(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data.copy()
        user = request.user

        service_id = data.get('service')
        carwash_id = data.get('carwash')
        if not service_id or not carwash_id:
            return Response({'error': 'Service and carwash ID are required.'}, status=400)

        try:
            service = Service.objects.get(id=service_id)
            carwash = CarWash.objects.get(id=carwash_id)
            tenant = carwash.tenant

            # Inject computed fields into data passed to serializer
            data['amount'] = service.price
            data['tenant'] = tenant.id
        except Service.DoesNotExist:
            return Response({'error': 'Service not found.'}, status=404)
        except CarWash.DoesNotExist:
            return Response({'error': 'Car wash not found.'}, status=404)

        # If no mpesa_number provided, use from profile
        if data.get("payment_method") == "mpesa":
            if not data.get("mpesa_number") and hasattr(user, "phone_number"):
                data["mpesa_number"] = user.phone_number

        serializer = BookingCreateSerializer(data=data, context={"request": request})
        if serializer.is_valid():
            booking = serializer.save()

            # Response contains created booking
            return Response({
                'status': 'created',
                'booking': BookingCreateSerializer(booking).data  # fresh serialize with ID
            }, status=201)

        return Response(serializer.errors, status=400)
