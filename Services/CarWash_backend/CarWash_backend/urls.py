from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/tenant/',include('Tenant.urls')),
    path('api/bookings/', include('bookings.urls')),
    path('api/analysis/', include('analysis.urls')),
    path('api/customer/', include('customer.urls')),
    
    
]

