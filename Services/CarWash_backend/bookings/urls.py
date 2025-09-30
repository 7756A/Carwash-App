from django.urls import path
from . import views
from .views import (
    TenantBookingList,
    CreateBooking,
    mpesa_callback,
)

urlpatterns = [
    # Tenant endpoints

    path('tenant/bookings/', TenantBookingList.as_view(), name='tenant-bookings'),
    

    # Customer endpoints
    
    path('customer/bookings/create/', CreateBooking.as_view(), name='create-booking'),

    path('mpesa/callback/', mpesa_callback, name='mpesa-callback'),
    


]
