"""Pydantic schemas for Farmer and Agricultural Officer profiles."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.auth import UserResponse
from app.schemas.validators import (
    clean_optional_text,
    clean_required_text,
    validate_optional_pincode,
    validate_phone_format,
)


class PreferredLanguageUpdate(BaseModel):
    """Schema to update a user's preferred language."""

    preferred_language: str = Field(..., min_length=2, max_length=50)

    @field_validator("preferred_language")
    @classmethod
    def validate_language(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)


class FarmerProfileUpsert(BaseModel):
    """Create or update schema for a Farmer profile."""

    village: str | None = Field(default=None, max_length=120)
    taluk_or_block: str | None = Field(default=None, max_length=120)
    district: str = Field(..., min_length=2, max_length=120)
    state: str = Field(..., min_length=2, max_length=120)
    pincode: str | None = Field(default=None, max_length=12)
    farming_experience_years: int | None = Field(default=None, ge=0, le=90)
    education_level: str | None = Field(default=None, max_length=100)
    primary_occupation: str = Field(default="Farming", min_length=2, max_length=120)
    bio: str | None = Field(default=None, max_length=1000)

    # Optional user-level fields updatable alongside profile
    preferred_language: str | None = Field(default=None, min_length=2, max_length=50)
    full_name: str | None = Field(default=None, min_length=2, max_length=150)
    phone_number: str | None = Field(default=None, min_length=7, max_length=20)

    @field_validator("district", "state", "primary_occupation")
    @classmethod
    def validate_required_fields(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)

    @field_validator("village", "taluk_or_block", "education_level", "bio")
    @classmethod
    def normalize_optional_fields(cls, value: str | None) -> str | None:
        return clean_optional_text(value)

    @field_validator("pincode")
    @classmethod
    def validate_pincode(cls, value: str | None) -> str | None:
        return validate_optional_pincode(value)

    @field_validator("preferred_language", "full_name")
    @classmethod
    def validate_optional_user_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return clean_required_text(value, min_length=2)

    @field_validator("phone_number")
    @classmethod
    def validate_optional_phone(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return validate_phone_format(value)


class FarmerProfileResponse(BaseModel):
    """Response schema for Farmer profile with linked User info."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    village: str | None
    taluk_or_block: str | None
    district: str
    state: str
    pincode: str | None
    farming_experience_years: int | None
    education_level: str | None
    primary_occupation: str
    bio: str | None
    created_at: datetime
    updated_at: datetime
    user: UserResponse
    farms_count: int = 0


class OfficerProfileUpsert(BaseModel):
    """Create or update schema for an Agricultural Officer profile."""

    designation: str = Field(..., min_length=2, max_length=150)
    department: str | None = Field(default=None, max_length=150)
    specialization: str = Field(..., min_length=2, max_length=200)
    qualifications: str | None = Field(default=None, max_length=255)
    experience_years: int = Field(default=0, ge=0, le=70)
    languages_spoken: str = Field(default="English", min_length=2, max_length=255)
    office_location: str | None = Field(default=None, max_length=200)
    district: str = Field(..., min_length=2, max_length=120)
    state: str = Field(..., min_length=2, max_length=120)
    is_available: bool = True
    availability_hours: str | None = Field(default=None, max_length=120)
    bio: str | None = Field(default=None, max_length=1000)

    # Optional user-level fields updatable alongside profile
    preferred_language: str | None = Field(default=None, min_length=2, max_length=50)
    full_name: str | None = Field(default=None, min_length=2, max_length=150)
    phone_number: str | None = Field(default=None, min_length=7, max_length=20)

    @field_validator("designation", "specialization", "languages_spoken", "district", "state")
    @classmethod
    def validate_required_fields(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)

    @field_validator(
        "department",
        "qualifications",
        "office_location",
        "availability_hours",
        "bio",
    )
    @classmethod
    def normalize_optional_fields(cls, value: str | None) -> str | None:
        return clean_optional_text(value)

    @field_validator("preferred_language", "full_name")
    @classmethod
    def validate_optional_user_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return clean_required_text(value, min_length=2)

    @field_validator("phone_number")
    @classmethod
    def validate_optional_phone(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return validate_phone_format(value)


class OfficerAvailabilityUpdate(BaseModel):
    """Schema for quick officer availability status toggle."""

    is_available: bool
    availability_hours: str | None = Field(default=None, max_length=120)

    @field_validator("availability_hours")
    @classmethod
    def normalize_hours(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class OfficerProfileResponse(BaseModel):
    """Response schema for Agricultural Officer profile with linked User info."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    designation: str
    department: str | None
    specialization: str
    qualifications: str | None
    experience_years: int
    languages_spoken: str
    office_location: str | None
    district: str
    state: str
    is_available: bool
    availability_hours: str | None
    bio: str | None
    created_at: datetime
    updated_at: datetime
    user: UserResponse

