from django.db import models
from Tenant.models import CarWash, Tenant, Service, Staff
from users.models import CustomUser

class Booking(models.Model):
    PAYMENT_METHOD_CHOICES = [
        ('mpesa', 'M-Pesa'),
        ('paypal', 'PayPal'),
        ('visa', 'Visa'),
    ]

    BOOKING_SOURCE_CHOICES = [
        ('online', 'Online'),
        ('walk_in', 'Walk-In'),
    ]

    STATUS_CHOICES = [
        ('failed', 'failed'),
        ('confirmed', 'confirmed'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    carwash = models.ForeignKey(CarWash, on_delete=models.CASCADE)
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    staff = models.ForeignKey(Staff, on_delete=models.SET_NULL, null=True, blank=True)

    customer = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='bookings')
    customer_name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=20)

    amount = models.DecimalField(max_digits=10, decimal_places=2)
    booking_source = models.CharField(max_length=20, choices=BOOKING_SOURCE_CHOICES, default='online')
    time_slot = models.DateTimeField()
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES, null=True, blank=True)
    payment_reference = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    def __str__(self):
        return f"Booking #{self.id} - {self.customer.username}"

    class Meta:
        ordering = ['-created_at']
