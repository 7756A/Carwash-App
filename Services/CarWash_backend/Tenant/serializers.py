from rest_framework import serializers
from .models import Tenant, CarWash, Service, Staff
from django.contrib.auth import get_user_model
from users.models import CustomUser

from rest_framework import serializers
from django.db import transaction
from .models import Tenant, CustomUser

class TenantRegistrationSerializer(serializers.ModelSerializer):
    username = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Tenant
        fields = ['name', 'email', 'phone_number', 'username', 'password']

    @transaction.atomic
    def create(self, validated_data):
        username = validated_data.pop('username')
        password = validated_data.pop('password')

        # Create the tenant first
        tenant = Tenant.objects.create(
            name=validated_data['name'],
            email=validated_data['email'],
            phone_number=validated_data['phone_number']
        )

        # Create associated tenant admin user
        CustomUser.objects.create_user(
            username=username,
            password=password,
            email=tenant.email,
            phone_number=tenant.phone_number,
            role='tenant',
            tenant=tenant
        )

        return tenant

class CarWashSerializer(serializers.ModelSerializer):
    class Meta:
        model = CarWash
        fields = ['id', 'name', 'location',  'latitude', 'longitude','description']

class ServiceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ['carwash', 'name', 'description', 'price', 'duration_minutes']
    
    def validate_carwash(self, carwash):
        request = self.context['request']
        user = request.user
        if carwash.tenant != user.tenant:
            raise serializers.ValidationError("You can only add services to your own carwash.")
        return carwash

class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ['id', 'name', 'description', 'price', 'duration_minutes']
        read_only_fields = fields


class StaffSerializer(serializers.ModelSerializer):
    class Meta:
        model = Staff
        fields = ['id', 'carwash', 'name', 'is_active']

    def validate_carwash(self, value):
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            if value.tenant != request.user.tenant:
                raise serializers.ValidationError("You are not authorized to assign staff to this carwash.")
        return value

    def create(self, validated_data):
        # Automatically assign tenant from request
        request = self.context.get('request')
        if request and hasattr(request.user, 'tenant'):
            validated_data['tenant'] = request.user.tenant
        return super().create(validated_data)
