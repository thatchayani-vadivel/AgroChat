"""Pydantic schemas for Farmer and Agricultural Officer authentication."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.core.constants import UserRole
from app.schemas.validators import clean_required_text, validate_phone_format


class UserRegisterRequest(BaseModel):
    """Request schema for Farmer or Agricultural Officer registration."""

    full_name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    phone_number: str = Field(..., min_length=7, max_length=20)
    password: str = Field(..., min_length=8, max_length=72)
    preferred_language: str = Field(default="English", min_length=2, max_length=50)

    @field_validator("full_name", "preferred_language")
    @classmethod
    def validate_non_blank(cls, value: str) -> str:
        """Trim surrounding whitespace and reject blank strings."""
        return clean_required_text(value, min_length=2)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: EmailStr) -> str:
        """Normalize email address to lowercase."""
        return str(value).strip().lower()

    @field_validator("phone_number")
    @classmethod
    def validate_phone_number(cls, value: str) -> str:
        """Ensure phone number contains valid characters and 7-15 digits."""
        return validate_phone_format(value)

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        """Ensure password is non-blank and fits within bcrypt's 72-byte limit."""
        if not value.strip():
            raise ValueError("Password cannot be only whitespace.")
        if len(value.encode("utf-8")) > 72:
            raise ValueError("Password must not exceed 72 bytes.")
        return value


class UserLoginRequest(BaseModel):
    """Request schema for Farmer or Agricultural Officer login."""

    email: EmailStr
    password: str = Field(..., min_length=1, max_length=72)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: EmailStr) -> str:
        """Normalize email address to lowercase."""
        return str(value).strip().lower()


class UserResponse(BaseModel):
    """Public representation of a user (never exposes hashed_password)."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    email: EmailStr
    phone_number: str
    role: UserRole
    preferred_language: str
    is_active: bool
    created_at: datetime


class AuthTokenResponse(BaseModel):
    """Response returned on successful registration or login."""

    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse

