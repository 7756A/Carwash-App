from django.urls import path
from . import views
from .views import (
    TenantBookingList,
    CreateBooking,
    mpesa_callback,
    CustomerBookingsView

)

urlpatterns = [
    # Tenant endpoints

    path('tenant/bookings/', TenantBookingList.as_view(), name='tenant-bookings'),
    

    # Customer endpoints
    
    path('customer/bookings/create/', CreateBooking.as_view(), name='create-booking'),
    path("my-bookings/", CustomerBookingsView.as_view(), name="customer-bookings"),
    

    path('mpesa/callback/', mpesa_callback, name='mpesa-callback'),
    


]
