from rest_framework.permissions import BasePermission



class IsTenantAdmin(BasePermission):
    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and request.user.role == 'tenant_admin'
            and request.user.tenant is not None
        )
