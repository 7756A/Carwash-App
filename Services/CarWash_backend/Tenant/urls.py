from django.urls import path
from .views import AdminCreateTenant, TenantLoginView, TenantDashboard, TenantAddCarWash, AddServiceForTenant

urlpatterns = [
    path('admin/create-tenant/', AdminCreateTenant.as_view(), name='create-tenant'),
    path('login/', TenantLoginView.as_view(), name='login'),
    path("dashboard/", TenantDashboard.as_view(), name="tenant-dashboard"),
   
    path('tenant/add-carwash/', TenantAddCarWash.as_view(), name='add-carwash'),

    path('services/add/', AddServiceForTenant.as_view(), name='add-service'),
]
