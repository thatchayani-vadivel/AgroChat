"""Pydantic schemas for Agricultural Assistance Requests and Consultations."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.constants import ConsultationStatus, RequestPriority, RequestStatus
from app.schemas.validators import clean_optional_text, clean_required_text


class AssistanceRequestCreate(BaseModel):
    """Payload for a Farmer submitting an assistance request."""

    title: str = Field(..., min_length=4, max_length=200)
    category: str = Field(..., min_length=2, max_length=120)
    description: str = Field(..., min_length=10, max_length=3000)
    priority: RequestPriority = RequestPriority.MEDIUM
    farm_id: int | None = Field(default=None, ge=1)
    crop_id: int | None = Field(default=None, ge=1)
    preferred_officer_id: int | None = Field(default=None, ge=1)

    @field_validator("title", "category", "description")
    @classmethod
    def validate_texts(cls, value: str, info) -> str:
        min_len = 10 if info.field_name == "description" else 4 if info.field_name == "title" else 2
        return clean_required_text(value, min_length=min_len)


class RequestAcceptPayload(BaseModel):
    """Optional payload when an Agricultural Officer accepts a request."""

    officer_notes: str | None = Field(default=None, max_length=1000)

    @field_validator("officer_notes")
    @classmethod
    def normalize_notes(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class RequestRejectPayload(BaseModel):
    """Payload required when an Agricultural Officer rejects a request."""

    rejection_reason: str = Field(..., min_length=5, max_length=1000)

    @field_validator("rejection_reason")
    @classmethod
    def validate_reason(cls, value: str) -> str:
        return clean_required_text(value, min_length=5)


class RequestStatusUpdatePayload(BaseModel):
    """Payload for an Agricultural Officer updating request status and guidance."""

    status: RequestStatus
    officer_notes: str | None = Field(default=None, max_length=2000)
    guidance_summary: str | None = Field(default=None, max_length=3000)
    recommendations: str | None = Field(default=None, max_length=3000)

    @field_validator("status")
    @classmethod
    def validate_allowed_transition_status(cls, value: RequestStatus) -> RequestStatus:
        if value not in (RequestStatus.IN_PROGRESS, RequestStatus.RESOLVED):
            raise ValueError("Status must be either 'in_progress' or 'resolved'.")
        return value

    @field_validator("officer_notes", "guidance_summary", "recommendations")
    @classmethod
    def normalize_optional(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class AssistanceRequestResponse(BaseModel):
    """Response schema for an AssistanceRequest with linked metadata."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farmer_id: int
    officer_id: int | None
    farm_id: int | None
    crop_id: int | None
    title: str
    category: str
    description: str
    priority: RequestPriority
    status: RequestStatus
    officer_notes: str | None
    rejection_reason: str | None
    accepted_at: datetime | None
    resolved_at: datetime | None
    created_at: datetime
    updated_at: datetime

    farmer_name: str | None = None
    farmer_phone: str | None = None
    officer_name: str | None = None
    farm_name: str | None = None
    crop_name: str | None = None
    consultation_id: int | None = None


class ConsultationResponse(BaseModel):
    """Response schema for Consultation history and active guidance."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    request_id: int
    farmer_id: int
    officer_id: int
    status: ConsultationStatus
    guidance_summary: str | None
    recommendations: str | None
    started_at: datetime
    completed_at: datetime | None
    updated_at: datetime

    request_title: str | None = None
    request_category: str | None = None
    request_status: RequestStatus | None = None
    farmer_name: str | None = None
    officer_name: str | None = None
    farm_name: str | None = None
    crop_name: str | None = None

