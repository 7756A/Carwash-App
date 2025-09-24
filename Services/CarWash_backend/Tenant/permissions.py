from rest_framework.permissions import BasePermission

class IsTenantAdmin(BasePermission):
    def has_permission(self, request, view):
        tenant_id = view.kwargs.get('tenant_id')
        return (
            request.user.is_authenticated and
            request.user.role == 'TenantAdmin' and
            str(request.user.tenant_id) == str(tenant_id)
        )
