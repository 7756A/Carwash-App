from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.generics import RetrieveUpdateAPIView

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


class CustomerProfileView(RetrieveUpdateAPIView):
    serializer_class = CustomerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user.customer_profile
