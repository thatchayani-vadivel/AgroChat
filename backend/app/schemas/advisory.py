"""Pydantic schemas for Government Schemes, Loans, Insurance, Equipment Rentals, and Services."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.core.constants import EquipmentAvailability, SchemeCategory


class SchemeResponse(BaseModel):
    """Response schema for Government Schemes, Subsidies, Loans, and Insurance."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    category: SchemeCategory
    provider: str
    description: str
    benefits: str
    eligibility: str
    required_documents: str | None
    application_process: str | None
    official_link: str | None
    state: str
    is_active: bool
    created_at: datetime


class EquipmentRentalResponse(BaseModel):
    """Response schema for agricultural equipment rentals."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    equipment_name: str
    category: str
    description: str
    provider_name: str
    contact_phone: str
    location: str
    district: str
    state: str
    daily_rate_inr: float
    hourly_rate_inr: float | None
    availability_status: EquipmentAvailability
    created_at: datetime


class AgriculturalServiceResponse(BaseModel):
    """Response schema for nearby agricultural services and offices."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    service_type: str
    description: str
    address: str
    district: str
    state: str
    pincode: str | None
    contact_phone: str
    email: str | None
    working_hours: str | None
    latitude: float | None
    longitude: float | None
    created_at: datetime

