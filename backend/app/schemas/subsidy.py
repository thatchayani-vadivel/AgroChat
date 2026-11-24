"""Pydantic schemas for Farmer Subsidy Enquiries and Officer Guidance."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.validators import clean_optional_text, clean_required_text


class SubsidyDocumentResponse(BaseModel):
    """Response schema for a subsidy supporting document."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    enquiry_id: int
    document_name: str
    document_type: str
    file_path: str
    file_size_bytes: int
    created_at: datetime


class SubsidyEnquiryCreate(BaseModel):
    """Payload for submitting a government subsidy assistance enquiry."""

    subsidy_title: str = Field(..., min_length=2, max_length=200)
    scheme_id: int | None = Field(default=None, ge=1)
    farm_id: int | None = Field(default=None, ge=1)
    enquiry_details: str = Field(..., min_length=5, max_length=3000)

    @field_validator("subsidy_title", "enquiry_details")
    @classmethod
    def validate_required(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)


class SubsidyEnquiryGuidanceUpdate(BaseModel):
    """Payload for an Officer providing subsidy application guidance."""

    status: str = Field(..., min_length=2, max_length=50)
    officer_guidance: str = Field(..., min_length=5, max_length=3000)

    @field_validator("status", "officer_guidance")
    @classmethod
    def validate_texts(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)


class SubsidyEnquiryResponse(BaseModel):
    """Response schema for a subsidy enquiry."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farmer_id: int
    scheme_id: int | None
    farm_id: int | None
    subsidy_title: str
    enquiry_details: str
    status: str
    officer_guidance: str | None
    created_at: datetime
    updated_at: datetime
    documents: list[SubsidyDocumentResponse] = []
