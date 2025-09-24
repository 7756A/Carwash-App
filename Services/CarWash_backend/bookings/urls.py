from django.urls import path
from . import views
from .views import (
    TenantBookingList,
    CalendarBookingView,
    NearbyCarWashesView,
    ServiceListByCarWash,
    StaffAvailability,
    CreateBooking,
)

urlpatterns = [
    # Tenant endpoints

    path('tenant/bookings/', TenantBookingList.as_view(), name='tenant-bookings'),
    path('tenant/calendar/', CalendarBookingView.as_view(), name='calendar-bookings'),

    # Customer endpoints
    path('carwashes/', NearbyCarWashesView.as_view(), name='nearby-carwashes'),
    path('customer/services/', ServiceListByCarWash.as_view(), name='carwash-service-list'),
    path('customer/availability/', StaffAvailability.as_view(), name='staff-availability'),
    path('customer/bookings/create/', CreateBooking.as_view(), name='create-booking'),
    


]
