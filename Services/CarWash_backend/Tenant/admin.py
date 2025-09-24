from django.contrib import admin
from .models import Tenant, CarWash, Service, Staff
from django.contrib.auth.admin import UserAdmin


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ['name', 'email', 'phone_number']
    search_fields = ['name', 'email']



@admin.register(CarWash)
class CarWashAdmin(admin.ModelAdmin):
    list_display = ['name', 'tenant', 'location']  # Removed 'latitude', 'longitude'
    search_fields = ['name', 'location']
    list_filter = ['tenant']

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ['name', 'carwash', 'price', 'duration_minutes']
    search_fields = ['name']
    list_filter = ['carwash']


@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ['name', 'carwash', 'tenant', 'is_active']
    list_filter = ['tenant', 'carwash', 'is_active']
    search_fields = ['name']
