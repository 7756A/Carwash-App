from django.urls import path
from .views import PasswordResetRequestView, PasswordResetConfirmView

urlpatterns = [
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
]
