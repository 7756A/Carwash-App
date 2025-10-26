# tenant/models.py

from django.db import models
from django.contrib.auth.models import Group, Permission
from users.models import CustomUser  # ✅ Import only, don't redefine
from django.contrib.auth.hashers import make_password


class Tenant(models.Model):
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20)

    def __str__(self):
        return self.name


class CarWash(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='carwashes')
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    description = models.TextField(blank=True)

    # M-Pesa Configuration Fields
    mpesa_consumer_key = models.CharField(max_length=200)
    mpesa_consumer_secret = models.CharField(max_length=200)
    mpesa_shortcode = models.CharField(max_length=50)
    mpesa_passkey = models.CharField(max_length=300)
    mpesa_callback_url = models.URLField(max_length=100)
    mpesa_env = models.CharField(
        max_length=10,
        choices=[("sandbox", "Sandbox"), ("production", "Production")],
        default="sandbox"
    )

    def __str__(self):
        return self.name


class Staff(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name='staff')
    carwash = models.ForeignKey(CarWash, on_delete=models.CASCADE, related_name='staff')
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.carwash.name})"


class Service(models.Model):
    carwash = models.ForeignKey(CarWash, on_delete=models.CASCADE, related_name='services')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_minutes = models.IntegerField(default=30)

    def __str__(self):
        return f"{self.name} - {self.price} @ {self.carwash.name}"
