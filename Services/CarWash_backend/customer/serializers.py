# customer/serializers.py

from rest_framework import serializers
from users.models import CustomUser
from customer.models import CustomerProfile

class CustomerRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'password']

    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            role='Customer'  # ✅ Set role
        )
        CustomerProfile.objects.create(user=user)  # ✅ Auto-create profile
        return user

class CustomerProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = CustomerProfile
        fields = ['username', 'email', 'full_name', 'phone_number', 'profile_picture']
