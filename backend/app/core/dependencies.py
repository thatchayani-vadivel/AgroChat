"""FastAPI authentication and role-based authorization dependencies."""

from collections.abc import Callable

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.constants import UserRole
from app.core.exceptions import AuthenticationError, AuthorizationError
from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.user import User

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Validate Bearer JWT token and return the authenticated active User."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise AuthenticationError("Authentication credentials were not provided.")

    payload = decode_access_token(credentials.credentials)

    try:
        user_id = int(payload["sub"])
    except (TypeError, ValueError) as exc:
        raise AuthenticationError("Invalid user identifier in token.") from exc

    token_role = payload.get("role")
    user = db.get(User, user_id)
    if user is None:
        raise AuthenticationError("User account no longer exists.")

    if not user.is_active:
        raise AuthorizationError("User account is inactive.")

    if user.role.value != token_role:
        raise AuthenticationError("Token role does not match user account.")

    return user


def require_roles(*allowed_roles: UserRole) -> Callable[[User], User]:
    """Create a FastAPI dependency that restricts access to specific UserRoles."""

    def role_guard(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise AuthorizationError(
                "You do not have permission to access this resource."
            )
        return current_user

    return role_guard


get_current_farmer = require_roles(UserRole.FARMER)
get_current_officer = require_roles(UserRole.AGRICULTURAL_OFFICER)

