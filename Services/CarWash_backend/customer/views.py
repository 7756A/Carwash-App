from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.generics import RetrieveUpdateAPIView
from django.contrib.auth import authenticate 
from rest_framework_simplejwt.tokens import RefreshToken
from Tenant.models import CarWash, Service
from Tenant.serializers import CarWashSerializer, ServiceSerializer

from math import radians, cos, sin, asin, sqrt


from users.models import CustomUser
from .models import CustomerProfile
from .serializers import CustomerRegisterSerializer, CustomerProfileSerializer

class CustomerRegisterView(APIView):
    permission_classes = [permissions.AllowAny]  # Optional users can register without login

    def post(self, request):
        serializer = CustomerRegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'message': 'Account created successfully'}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CustomerLoginView(APIView):
    permission_classes = [permissions.AllowAny]  # Allow login without auth

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")

        user = authenticate(username=username, password=password)

        if user is None:
            return Response({"detail": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

        if user.role != "customer":  # ✅ restrict only to customers
            return Response({"detail": "This account is not a customer account"}, status=status.HTTP_403_FORBIDDEN)

        refresh = RefreshToken.for_user(user)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "username": user.username,
            "role": user.role,
            "customer_id": user.customer_profile.id if hasattr(user, "customer_profile") and user.customer_profile else None
        })

class CustomerProfileView(RetrieveUpdateAPIView):
    serializer_class = CustomerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user.customer_profile

class NearbyCarWashView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user_lat = float(request.query_params.get("lat"))
        user_lon = float(request.query_params.get("lon"))
        radius = float(request.query_params.get("radius", 10))  # default 10km

        nearby = []
        for carwash in CarWash.objects.exclude(latitude__isnull=True).exclude(longitude__isnull=True):
            distance = haversine(user_lon, user_lat, float(carwash.longitude), float(carwash.latitude))
            if distance <= radius:
                data = CarWashSerializer(carwash).data
                data["distance_km"] = round(distance, 2)
                nearby.append(data)

        return Response(nearby)
    

def haversine(lon1, lat1, lon2, lat2):
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return 6371 * c  # Earth radius in km

class CarWashServicesView(APIView):
    permission_classes = [permissions.IsAuthenticated]  # or AllowAny

    def get(self, request, carwash_id):
        services = Service.objects.filter(carwash_id=carwash_id)
        serializer = ServiceSerializer(services, many=True)
        return Response(serializer.data)
