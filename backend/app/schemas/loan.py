"""Pydantic schemas for Farmer Agricultural Loan Enquiries and Guidance."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.validators import clean_optional_text, clean_required_text


class LoanDocumentResponse(BaseModel):
    """Response schema for a loan supporting document."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    enquiry_id: int
    document_name: str
    document_type: str
    file_path: str
    file_size_bytes: int
    created_at: datetime


class LoanEnquiryCreate(BaseModel):
    """Payload for submitting an agricultural loan advisory enquiry."""

    loan_type: str = Field(..., min_length=2, max_length=100)
    scheme_id: int | None = Field(default=None, ge=1)
    preferred_bank: str | None = Field(default=None, max_length=150)
    requested_amount_inr: Decimal = Field(..., gt=0, le=100000000)
    purpose: str = Field(..., min_length=5, max_length=3000)
    annual_income_inr: Decimal | None = Field(default=None, ge=0, le=100000000)
    land_holding_acres: Decimal | None = Field(default=None, ge=0, le=100000)

    @field_validator("loan_type", "purpose")
    @classmethod
    def validate_required(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)

    @field_validator("preferred_bank")
    @classmethod
    def normalize_optional(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class LoanEnquiryGuidanceUpdate(BaseModel):
    """Payload for an Agricultural Officer providing guidance on a loan enquiry."""

    status: str = Field(..., min_length=2, max_length=50)
    officer_guidance: str = Field(..., min_length=5, max_length=3000)

    @field_validator("status", "officer_guidance")
    @classmethod
    def validate_texts(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)


class LoanEnquiryResponse(BaseModel):
    """Response schema for a loan enquiry with linked metadata."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farmer_id: int
    scheme_id: int | None
    loan_type: str
    preferred_bank: str | None
    requested_amount_inr: Decimal
    purpose: str
    annual_income_inr: Decimal | None
    land_holding_acres: Decimal | None
    status: str
    officer_guidance: str | None
    created_at: datetime
    updated_at: datetime
    documents: list[LoanDocumentResponse] = []
