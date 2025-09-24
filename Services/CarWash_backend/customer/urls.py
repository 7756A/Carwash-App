# customer/urls.py

from django.urls import path
from .views import CustomerRegisterView, CustomerProfileView
from rest_framework.authtoken.views import obtain_auth_token  # or JWT login

urlpatterns = [
    path('register/', CustomerRegisterView.as_view(), name='customer-register'),
    path('login/', obtain_auth_token, name='customer-login'),  # POST username & password
    path('profile/', CustomerProfileView.as_view(), name='customer-profile'),
    
]
