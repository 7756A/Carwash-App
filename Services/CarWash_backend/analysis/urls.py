from django.urls import path
from .views import (
    TenantKPIView,
    TenantCarwashKPIExportPDFView
)

urlpatterns = [
    path('tenant/<int:tenant_id>/kpi-summary/', TenantKPIView.as_view(), name='kpi-summary'),
    path('tenant/<int:tenant_id>/export/pdf/', TenantCarwashKPIExportPDFView.as_view(), name='export-pdf'),
]
