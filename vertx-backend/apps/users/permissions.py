"""
VERTX — Role-Based Permission Classes
Used across all apps to guard endpoints by role.
"""

from rest_framework.permissions import BasePermission


class IsViewer(BasePermission):
    """Allows access to authenticated viewers only."""
    message = 'Viewer access required.'

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_viewer)


class IsProducer(BasePermission):
    """Allows access to authenticated producers only."""
    message = 'Producer account required.'

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_producer)


class IsAdmin(BasePermission):
    """Allows access to platform admins only."""
    message = 'Admin access required.'

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_platform_admin)


class IsProducerOrAdmin(BasePermission):
    """Allows producers and admins."""
    message = 'Producer or admin access required.'

    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.is_producer or request.user.is_platform_admin)
        )


class IsOwnerOrAdmin(BasePermission):
    """
    Object-level permission: only the owner or an admin can act.
    The view must set `owner_field` on the object, defaulting to 'user'.
    """
    message = 'You do not have permission to modify this resource.'

    def has_object_permission(self, request, view, obj):
        if request.user.is_platform_admin:
            return True
        owner_field = getattr(view, 'owner_field', 'user')
        owner = getattr(obj, owner_field, None)
        return owner == request.user
