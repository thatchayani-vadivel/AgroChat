"""Authentication business logic for Farmers and Agricultural Officers."""

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.constants import UserRole
from app.core.exceptions import (
    AuthenticationError,
    AuthorizationError,
    DuplicateResourceError,
)
from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User
from app.schemas.auth import (
    AuthTokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)


def _build_auth_response(user: User) -> AuthTokenResponse:
    """Create JWT access token and serialized AuthTokenResponse for a user."""
    token, expires_in = create_access_token(
        user_id=user.id,
        role=user.role,
        email=user.email,
    )
    return AuthTokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=expires_in,
        user=UserResponse.model_validate(user),
    )


def register_user(
    db: Session,
    payload: UserRegisterRequest,
    role: UserRole,
) -> AuthTokenResponse:
    """Register a new Farmer or Agricultural Officer with unique email enforcement."""
    existing_user = db.scalar(select(User).where(User.email == payload.email))
    if existing_user is not None:
        raise DuplicateResourceError("An account with this email already exists.")

    new_user = User(
        full_name=payload.full_name,
        email=payload.email,
        phone_number=payload.phone_number,
        hashed_password=hash_password(payload.password),
        role=role,
        preferred_language=payload.preferred_language,
        is_active=True,
    )

    db.add(new_user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise DuplicateResourceError("An account with this email already exists.") from exc

    db.refresh(new_user)
    return _build_auth_response(new_user)


def authenticate_user(
    db: Session,
    payload: UserLoginRequest,
    expected_role: UserRole,
) -> AuthTokenResponse:
    """Authenticate credentials and enforce role-specific login access."""
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not verify_password(payload.password, user.hashed_password):
        raise AuthenticationError("Invalid email or password.")

    if not user.is_active:
        raise AuthorizationError("This account has been deactivated.")

    if user.role != expected_role:
        role_label = expected_role.value.replace("_", " ")
        raise AuthorizationError(
            f"Access denied. This portal is restricted to {role_label} accounts."
        )

    return _build_auth_response(user)

