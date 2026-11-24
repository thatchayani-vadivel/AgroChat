"""Business logic for Farms, Crops, Livestock, and Officer farm inspection."""

from fastapi import status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.core.constants import UserRole
from app.core.exceptions import AgroChatException, AuthorizationError, NotFoundError
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.farmer_profile import FarmerProfile
from app.models.livestock import Livestock
from app.models.user import User
from app.schemas.farm import (
    CropPayload,
    CropResponse,
    FarmPayload,
    FarmResponse,
    FarmerDetailsForOfficerResponse,
    LivestockPayload,
    LivestockResponse,
)
from app.services.profile_service import build_farmer_profile_response


def _load_farm(db: Session, farm_id: int) -> Farm:
    """Load a Farm with its farmer_profile, crops, and livestock or raise 404."""
    farm = db.scalar(
        select(Farm)
        .options(
            joinedload(Farm.farmer_profile),
            selectinload(Farm.crops),
            selectinload(Farm.livestock),
        )
        .where(Farm.id == farm_id)
    )
    if farm is None:
        raise NotFoundError("Farm not found.")
    return farm


def get_owned_farm(db: Session, farm_id: int, farmer_user: User) -> Farm:
    """Ensure the farm exists and belongs to the authenticated Farmer."""
    farm = _load_farm(db, farm_id)
    if farm.farmer_profile.user_id != farmer_user.id:
        raise AuthorizationError("You do not have permission to modify this farm.")
    return farm


def get_farm_for_viewer(db: Session, farm_id: int, current_user: User) -> Farm:
    """Allow farm access to the owning Farmer or any Agricultural Officer."""
    farm = _load_farm(db, farm_id)
    if (
        current_user.role == UserRole.FARMER
        and farm.farmer_profile.user_id != current_user.id
    ):
        raise AuthorizationError("You do not have permission to view this farm.")
    return farm


def _validate_crop_area(crop_area: float, farm: Farm) -> None:
    """Ensure a single crop's cultivated area does not exceed the farm's total area."""
    if crop_area > farm.total_area_acres:
        raise AgroChatException(
            detail=(
                f"Crop area ({crop_area} acres) cannot exceed total farm area "
                f"({farm.total_area_acres} acres)."
            ),
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Invalid Crop Area",
        )


def create_farm(db: Session, farmer_user: User, payload: FarmPayload) -> FarmResponse:
    """Create a new Farm for the authenticated Farmer."""
    farmer_profile = db.scalar(
        select(FarmerProfile).where(FarmerProfile.user_id == farmer_user.id)
    )
    if farmer_profile is None:
        raise AgroChatException(
            detail="Please complete your farmer profile before adding a farm.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Farmer Profile Required",
        )

    farm = Farm(farmer_profile_id=farmer_profile.id, **payload.model_dump())
    db.add(farm)
    db.commit()
    return FarmResponse.model_validate(_load_farm(db, farm.id))


def list_farmer_farms(db: Session, farmer_user: User) -> list[FarmResponse]:
    """List all farms belonging to the authenticated Farmer."""
    farmer_profile = db.scalar(
        select(FarmerProfile).where(FarmerProfile.user_id == farmer_user.id)
    )
    if farmer_profile is None:
        return []

    farms = db.scalars(
        select(Farm)
        .options(selectinload(Farm.crops), selectinload(Farm.livestock))
        .where(Farm.farmer_profile_id == farmer_profile.id)
        .order_by(Farm.id.desc())
    ).all()
    return [FarmResponse.model_validate(farm) for farm in farms]


def get_farm_details(db: Session, farm_id: int, current_user: User) -> FarmResponse:
    """Return detailed Farm info including crops and livestock."""
    farm = get_farm_for_viewer(db, farm_id, current_user)
    return FarmResponse.model_validate(farm)


def update_farm(
    db: Session, farm_id: int, farmer_user: User, payload: FarmPayload
) -> FarmResponse:
    """Update a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    for field, value in payload.model_dump().items():
        setattr(farm, field, value)
    db.commit()
    return FarmResponse.model_validate(_load_farm(db, farm.id))


def delete_farm(db: Session, farm_id: int, farmer_user: User) -> None:
    """Delete a Farmer's owned farm and its cascading crops/livestock."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    db.delete(farm)
    db.commit()


def list_crops(db: Session, farm_id: int, current_user: User) -> list[CropResponse]:
    """List all crops for a farm accessible by the current user."""
    farm = get_farm_for_viewer(db, farm_id, current_user)
    return [CropResponse.model_validate(crop) for crop in farm.crops]


def add_crop(
    db: Session, farm_id: int, farmer_user: User, payload: CropPayload
) -> CropResponse:
    """Add a crop to a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    _validate_crop_area(payload.area_acres, farm)
    crop = Crop(farm_id=farm.id, **payload.model_dump())
    db.add(crop)
    db.commit()
    db.refresh(crop)
    return CropResponse.model_validate(crop)


def update_crop(
    db: Session,
    farm_id: int,
    crop_id: int,
    farmer_user: User,
    payload: CropPayload,
) -> CropResponse:
    """Update a crop on a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    _validate_crop_area(payload.area_acres, farm)
    crop = db.scalar(select(Crop).where(Crop.id == crop_id, Crop.farm_id == farm.id))
    if crop is None:
        raise NotFoundError("Crop not found on this farm.")
    for field, value in payload.model_dump().items():
        setattr(crop, field, value)
    db.commit()
    db.refresh(crop)
    return CropResponse.model_validate(crop)


def delete_crop(
    db: Session, farm_id: int, crop_id: int, farmer_user: User
) -> None:
    """Delete a crop from a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    crop = db.scalar(select(Crop).where(Crop.id == crop_id, Crop.farm_id == farm.id))
    if crop is None:
        raise NotFoundError("Crop not found on this farm.")
    db.delete(crop)
    db.commit()


def list_livestock(
    db: Session, farm_id: int, current_user: User
) -> list[LivestockResponse]:
    """List all livestock/allied activities for a farm accessible by the user."""
    farm = get_farm_for_viewer(db, farm_id, current_user)
    return [LivestockResponse.model_validate(item) for item in farm.livestock]


def add_livestock(
    db: Session, farm_id: int, farmer_user: User, payload: LivestockPayload
) -> LivestockResponse:
    """Add livestock or allied agricultural activity to a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    item = Livestock(farm_id=farm.id, **payload.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return LivestockResponse.model_validate(item)


def update_livestock(
    db: Session,
    farm_id: int,
    livestock_id: int,
    farmer_user: User,
    payload: LivestockPayload,
) -> LivestockResponse:
    """Update livestock or allied activity on a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    item = db.scalar(
        select(Livestock).where(Livestock.id == livestock_id, Livestock.farm_id == farm.id)
    )
    if item is None:
        raise NotFoundError("Livestock entry not found on this farm.")
    for field, value in payload.model_dump().items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return LivestockResponse.model_validate(item)


def delete_livestock(
    db: Session, farm_id: int, livestock_id: int, farmer_user: User
) -> None:
    """Delete livestock or allied activity from a Farmer's owned farm."""
    farm = get_owned_farm(db, farm_id, farmer_user)
    item = db.scalar(
        select(Livestock).where(Livestock.id == livestock_id, Livestock.farm_id == farm.id)
    )
    if item is None:
        raise NotFoundError("Livestock entry not found on this farm.")
    db.delete(item)
    db.commit()


def get_farmer_details_for_officer(
    db: Session, farmer_user_id: int
) -> FarmerDetailsForOfficerResponse:
    """Allow an Agricultural Officer to inspect a Farmer's profile and farms."""
    profile = db.scalar(
        select(FarmerProfile)
        .join(FarmerProfile.user)
        .options(
            joinedload(FarmerProfile.user),
            selectinload(FarmerProfile.farms).selectinload(Farm.crops),
            selectinload(FarmerProfile.farms).selectinload(Farm.livestock),
        )
        .where(
            FarmerProfile.user_id == farmer_user_id,
            User.role == UserRole.FARMER,
        )
    )
    if profile is None:
        raise NotFoundError("Farmer profile not found.")

    return FarmerDetailsForOfficerResponse(
        profile=build_farmer_profile_response(db, profile),
        farms=[FarmResponse.model_validate(farm) for farm in profile.farms],
    )

