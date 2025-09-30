from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.db.models import Count, Sum, Avg
from bookings.models import Booking
from Tenant.permissions import IsTenantAdmin
from bookings.models import Booking
from .serializers import (
    CarWashSerializer,
    ServiceCreateSerializer,
    StaffSerializer,
    TenantRegistrationSerializer
)
from .models import Tenant, CarWash, Service, Staff


class AdminCreateTenant(APIView):
    def post(self, request):
        serializer = TenantRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Tenant and TenantAdmin created successfully."}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TenantLoginView(APIView):
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        user = authenticate(username=username, password=password)

        if user is None:
            return Response({"detail": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

        if user.role != "tenant_admin":  # ✅ restrict only to tenants
            return Response({"detail": "This account is not a tenant account"}, status=status.HTTP_403_FORBIDDEN)

        refresh = RefreshToken.for_user(user)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "username": user.username,
            "role": user.role,
            "tenant_id": user.tenant.id if hasattr(user, "tenant") and user.tenant else None
        })

class TenantAddCarWash(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.role != 'TenantAdmin':
            return Response({"error": "Only Tenant Admins can add car washes."}, status=403)

        serializer = CarWashSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(tenant=user.tenant)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    

class TenantDashboard(APIView):
    permission_classes = [IsAuthenticated, IsTenantAdmin]

    def get(self, request):
        tenant = request.user.tenant

        # Quick stats
        total_bookings = Booking.objects.filter(tenant=tenant).count()
        completed_washes = Booking.objects.filter(tenant=tenant, status='completed').count()
        pending_requests = Booking.objects.filter(tenant=tenant, status='pending').count()
        revenue = (
            Booking.objects.filter(tenant=tenant, status='completed')
            .aggregate(total=Sum('amount'))['total'] or 0
        )

        # Recent bookings (last 5)
        recent_bookings = Booking.objects.filter(tenant=tenant).order_by('-created_at')[:5]

        return Response({
            "quick_stats": {
                "total_bookings": total_bookings,
                "completed_washes": completed_washes,
                "pending_requests": pending_requests,
                "revenue": revenue,
            },
            "recent_activity": {
                "bookings": list(
                    recent_bookings.values(
                        'id',
                        'customer__username',
                        'service__name',
                        'status',
                        'amount',
                        'created_at'
                    )
                )
            }
        })



class AddServiceForTenant(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user

        if user.role != "TenantAdmin":
            return Response({"detail": "Only TenantAdmins can add services."}, status=403)

        serializer = ServiceCreateSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)


class AddStaff(APIView):
    permission_classes = [IsAuthenticated, IsTenantAdmin]

    def post(self, request):
        tenant = request.user.tenant
        carwash_id = request.data.get('carwash_id')
        if not carwash_id:
            return Response({'error': 'carwash_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        if not CarWash.objects.filter(id=carwash_id, tenant=tenant).exists():
            return Response({'error': 'Unauthorized or invalid carwash'}, status=status.HTTP_403_FORBIDDEN)

        serializer = StaffSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response({'status': 'created', 'staff': serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



