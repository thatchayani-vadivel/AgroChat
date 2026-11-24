"""Password hashing and JWT access-token utilities."""

from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
import jwt

from app.core.config import get_settings
from app.core.constants import UserRole
from app.core.exceptions import AuthenticationError

MAX_BCRYPT_BYTES = 72


def hash_password(plain_password: str) -> str:
    """Hash a plaintext password securely using bcrypt."""
    password_bytes = plain_password.encode("utf-8")
    if len(password_bytes) > MAX_BCRYPT_BYTES:
        raise ValueError("Password must not exceed 72 bytes.")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password_bytes, salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a stored bcrypt hash."""
    password_bytes = plain_password.encode("utf-8")
    if len(password_bytes) > MAX_BCRYPT_BYTES:
        return False
    try:
        return bcrypt.checkpw(password_bytes, hashed_password.encode("utf-8"))
    except ValueError:
        return False


def create_access_token(
    user_id: int,
    role: UserRole,
    email: str,
    expires_delta: timedelta | None = None,
) -> tuple[str, int]:
    """Generate a signed JWT access token and return (token, expires_in_seconds)."""
    settings = get_settings()
    lifetime = expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    now = datetime.now(timezone.utc)
    expire_at = now + lifetime

    payload: dict[str, Any] = {
        "sub": str(user_id),
        "role": role.value,
        "email": email,
        "iat": int(now.timestamp()),
        "exp": int(expire_at.timestamp()),
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, int(lifetime.total_seconds())


def decode_access_token(token: str) -> dict[str, Any]:
    """Decode and validate a JWT access token."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
    except jwt.ExpiredSignatureError as exc:
        raise AuthenticationError("Access token has expired. Please log in again.") from exc
    except jwt.InvalidTokenError as exc:
        raise AuthenticationError("Invalid authentication token.") from exc

    if not payload.get("sub") or not payload.get("role"):
        raise AuthenticationError("Authentication token is missing required claims.")
    return payload

