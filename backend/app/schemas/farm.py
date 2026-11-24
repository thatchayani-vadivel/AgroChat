"""Pydantic schemas for Farms, Crops, Livestock, and Officer farm inspection."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.schemas.profile import FarmerProfileResponse
from app.schemas.validators import clean_optional_text, clean_required_text


class CropPayload(BaseModel):
    """Create or update payload for a Crop on a Farm."""

    crop_name: str = Field(..., min_length=2, max_length=120)
    variety: str | None = Field(default=None, max_length=120)
    season: str = Field(..., min_length=2, max_length=80)
    area_acres: float = Field(..., gt=0, le=100000)
    sowing_date: date | None = None
    expected_harvest_date: date | None = None
    growth_stage: str | None = Field(default=None, max_length=100)
    estimated_yield_kg: float | None = Field(default=None, ge=0, le=10000000)
    notes: str | None = Field(default=None, max_length=1000)

    @field_validator("crop_name", "season")
    @classmethod
    def validate_required_fields(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)

    @field_validator("variety", "growth_stage", "notes")
    @classmethod
    def normalize_optional_fields(cls, value: str | None) -> str | None:
        return clean_optional_text(value)

    @model_validator(mode="after")
    def validate_dates(self) -> "CropPayload":
        if (
            self.sowing_date is not None
            and self.expected_harvest_date is not None
            and self.expected_harvest_date < self.sowing_date
        ):
            raise ValueError("expected_harvest_date cannot be earlier than sowing_date.")
        return self


class CropResponse(BaseModel):
    """Response schema for a Crop."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farm_id: int
    crop_name: str
    variety: str | None
    season: str
    area_acres: float
    sowing_date: date | None
    expected_harvest_date: date | None
    growth_stage: str | None
    estimated_yield_kg: float | None
    notes: str | None
    created_at: datetime
    updated_at: datetime


class LivestockPayload(BaseModel):
    """Create or update payload for Livestock or allied agricultural activities."""

    category: str = Field(..., min_length=2, max_length=100)
    breed_or_type: str | None = Field(default=None, max_length=120)
    count: int = Field(default=1, ge=1, le=100000)
    purpose: str | None = Field(default=None, max_length=150)
    health_status: str = Field(default="Healthy", min_length=2, max_length=100)
    notes: str | None = Field(default=None, max_length=1000)

    @field_validator("category", "health_status")
    @classmethod
    def validate_required_fields(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)

    @field_validator("breed_or_type", "purpose", "notes")
    @classmethod
    def normalize_optional_fields(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class LivestockResponse(BaseModel):
    """Response schema for Livestock."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farm_id: int
    category: str
    breed_or_type: str | None
    count: int
    purpose: str | None
    health_status: str
    notes: str | None
    created_at: datetime
    updated_at: datetime


class FarmPayload(BaseModel):
    """Create or update payload for a Farm."""

    farm_name: str = Field(..., min_length=2, max_length=150)
    total_area_acres: float = Field(..., gt=0, le=100000)
    soil_type: str = Field(..., min_length=2, max_length=100)
    irrigation_type: str = Field(..., min_length=2, max_length=100)
    water_source: str | None = Field(default=None, max_length=120)
    location: str = Field(..., min_length=2, max_length=255)
    district: str = Field(..., min_length=2, max_length=120)
    state: str = Field(..., min_length=2, max_length=120)
    ownership_type: str | None = Field(default=None, max_length=80)
    notes: str | None = Field(default=None, max_length=1000)

    @field_validator("farm_name", "soil_type", "irrigation_type", "location", "district", "state")
    @classmethod
    def validate_required_fields(cls, value: str) -> str:
        return clean_required_text(value, min_length=2)

    @field_validator("water_source", "ownership_type", "notes")
    @classmethod
    def normalize_optional_fields(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class FarmResponse(BaseModel):
    """Response schema for a Farm including its Crops and Livestock."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farmer_profile_id: int
    farm_name: str
    total_area_acres: float
    soil_type: str
    irrigation_type: str
    water_source: str | None
    location: str
    district: str
    state: str
    ownership_type: str | None
    notes: str | None
    created_at: datetime
    updated_at: datetime
    crops: list[CropResponse] = []
    livestock: list[LivestockResponse] = []


class FarmerDetailsForOfficerResponse(BaseModel):
    """Composite farmer and farm view returned to Agricultural Officers."""

    profile: FarmerProfileResponse
    farms: list[FarmResponse]


class MessageResponse(BaseModel):
    """Standard confirmation message response for delete operations."""

    success: bool = True
    message: str
