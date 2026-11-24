"""Pydantic schemas for Farmer Equipment Rental Bookings."""

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.schemas.validators import clean_optional_text, clean_required_text


class RentalBookingCreate(BaseModel):
    """Payload to request an equipment rental booking."""

    equipment_id: int = Field(..., ge=1)
    start_date: date
    end_date: date
    rental_type: str = Field(default="daily", max_length=20)  # 'daily' or 'hourly'
    duration_units: int = Field(default=1, ge=1, le=365)
    delivery_location: str = Field(..., min_length=3, max_length=255)
    contact_phone: str = Field(..., min_length=10, max_length=20)
    farmer_notes: str | None = Field(default=None, max_length=1000)

    @field_validator("delivery_location", "contact_phone")
    @classmethod
    def validate_required(cls, value: str) -> str:
        return clean_required_text(value, min_length=3)

    @field_validator("farmer_notes")
    @classmethod
    def normalize_optional(cls, value: str | None) -> str | None:
        return clean_optional_text(value)

    @model_validator(mode="after")
    def validate_dates(self) -> "RentalBookingCreate":
        if self.end_date < self.start_date:
            raise ValueError("end_date cannot be earlier than start_date.")
        return self


class RentalBookingStatusUpdate(BaseModel):
    """Payload for updating booking status."""

    booking_status: str = Field(..., min_length=2, max_length=50)
    provider_response: str | None = Field(default=None, max_length=1000)

    @field_validator("booking_status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)


class RentalBookingResponse(BaseModel):
    """Response schema for an equipment rental booking."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    equipment_id: int
    farmer_id: int
    start_date: date
    end_date: date
    rental_type: str
    duration_units: int
    total_cost_inr: Decimal
    delivery_location: str
    contact_phone: str
    booking_status: str
    farmer_notes: str | None
    provider_response: str | None
    created_at: datetime
    updated_at: datetime
    equipment_name: str | None = None
