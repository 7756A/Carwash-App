from django.urls import path
from .views import AdminCreateTenant, TenantLoginView, TenantDashboard, CarWashServicesView, TenantAddCarWash, AddServiceForTenant

urlpatterns = [
    path('admin/create-tenant/', AdminCreateTenant.as_view(), name='create-tenant'),
    path('login/', TenantLoginView.as_view(), name='login'),
    path("dashboard/", TenantDashboard.as_view(), name="tenant-dashboard"),
    
    path("carwash/<int:carwash_id>/services/", CarWashServicesView.as_view(), name="carwash-services"),
   
    path('tenant/add-carwash/', TenantAddCarWash.as_view(), name='add-carwash'),

    path('services/add/', AddServiceForTenant.as_view(), name='add-service'),
]
