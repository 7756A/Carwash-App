from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.generics import RetrieveUpdateAPIView
from django.contrib.auth import authenticate 
from rest_framework_simplejwt.tokens import RefreshToken


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
