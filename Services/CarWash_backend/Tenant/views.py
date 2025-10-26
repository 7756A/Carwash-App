from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
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
from users.models import CustomUser


class AdminCreateTenant(APIView):
    def post(self, request):
        data = request.data

        name = data.get("name")
        email = data.get("email")
        username = data.get("username")
        password = data.get("password")
        phone_number = data.get("phone_number")

        if not all([name, email, username, password]):
            return Response(
                {"error": "Missing required fields (name, email, username, password)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ✅ Step 1: Create the tenant
        tenant = Tenant.objects.create(name=name)

        # ✅ Step 2: Create the tenant admin user linked to the tenant
        tenant_admin = CustomUser.objects.create_user(
            username=username,
            email=email,
            password=password,
            phone_number=phone_number,
            role="tenant_admin",
            tenant=tenant,
            is_staff=True,
        )

        return Response(
            {
                "message": "Tenant and Tenant Admin created successfully.",
                "tenant_id": tenant.id,
                "tenant_admin": tenant_admin.username,
            },
            status=status.HTTP_201_CREATED,
        )
    
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
        if user.role != 'tenant_admin':
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

        if user.role != "tenant_admin":
            return Response({"detail": "Only TenantAdmins can add services."}, status=403)

        serializer = ServiceCreateSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

class CarWashServicesView(APIView):
    permission_classes = [AllowAny]  # Anyone (customers) can view

    def get(self, request, carwash_id):
        try:
            carwash = CarWash.objects.get(id=carwash_id)
        except CarWash.DoesNotExist:
            return Response({"error": "Carwash not found"}, status=status.HTTP_404_NOT_FOUND)

        services = carwash.services.all()
        serializer = ServiceSerializer(services, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

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



