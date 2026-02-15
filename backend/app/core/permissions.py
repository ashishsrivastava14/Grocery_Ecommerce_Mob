"""Permission and role checks."""
from functools import wraps
from fastapi import HTTPException, status
from app.models.user import UserRole


class RoleChecker:
    """Dependency to check user roles."""

    def __init__(self, allowed_roles: list[UserRole]):
        self.allowed_roles = allowed_roles

    def __call__(self, current_user):
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return current_user


# Predefined role checkers
allow_admin = RoleChecker([UserRole.ADMIN])
allow_vendor = RoleChecker([UserRole.VENDOR, UserRole.ADMIN])
allow_customer = RoleChecker([UserRole.CUSTOMER, UserRole.ADMIN])
allow_delivery = RoleChecker([UserRole.DELIVERY, UserRole.ADMIN])
allow_all_authenticated = RoleChecker(
    [UserRole.CUSTOMER, UserRole.VENDOR, UserRole.DELIVERY, UserRole.ADMIN]
)
