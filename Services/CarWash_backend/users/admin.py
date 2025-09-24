from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ['username', 'email', 'role', 'tenant', 'is_staff', 'is_active']
    list_filter = ['role', 'tenant', 'is_active']
    search_fields = ['username', 'email']
    ordering = ['username']

    fieldsets = UserAdmin.fieldsets + (
        (None, {'fields': ('role', 'tenant')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        (None, {'fields': ('role', 'tenant')}),
    )
