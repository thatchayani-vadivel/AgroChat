"""REST endpoints for Farmer profile management and Officer farmer inspection."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer, get_current_officer
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import UserResponse
from app.schemas.farm import FarmerDetailsForOfficerResponse
from app.schemas.profile import (
    FarmerProfileResponse,
    FarmerProfileUpsert,
    PreferredLanguageUpdate,
)
from app.services.farm_service import get_farmer_details_for_officer
from app.services.profile_service import (
    build_farmer_profile_response,
    create_farmer_profile,
    get_farmer_profile,
    update_user_preferred_language,
    upsert_farmer_profile,
)

router = APIRouter(prefix="/api/farmers", tags=["Farmer Profile"])


@router.get(
    "/profile",
    response_model=FarmerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get My Farmer Profile",
    description="Return the authenticated Farmer's profile details.",
)
def read_my_farmer_profile(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> FarmerProfileResponse:
    profile = get_farmer_profile(db, current_farmer.id)
    return build_farmer_profile_response(db, profile)


@router.post(
    "/profile",
    response_model=FarmerProfileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Farmer Profile",
    description="Create a profile for the authenticated Farmer.",
)
def create_my_farmer_profile(
    payload: FarmerProfileUpsert,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> FarmerProfileResponse:
    return create_farmer_profile(db, current_farmer, payload)


@router.put(
    "/profile",
    response_model=FarmerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Create or Update Farmer Profile",
    description="Create or update the authenticated Farmer's profile and optional contact/language details.",
)
def update_my_farmer_profile(
    payload: FarmerProfileUpsert,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> FarmerProfileResponse:
    return upsert_farmer_profile(db, current_farmer, payload)


@router.patch(
    "/preferred-language",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Farmer Preferred Language",
    description="Update the authenticated Farmer's preferred language.",
)
def update_farmer_language(
    payload: PreferredLanguageUpdate,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> UserResponse:
    return update_user_preferred_language(db, current_farmer, payload.preferred_language)


@router.get(
    "/{farmer_user_id}",
    response_model=FarmerDetailsForOfficerResponse,
    status_code=status.HTTP_200_OK,
    summary="Inspect Farmer & Farm Details (Officer Only)",
    description="Allow an Agricultural Officer to view a Farmer's profile, farms, crops, and livestock.",
)
def inspect_farmer_details(
    farmer_user_id: int,
    _current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> FarmerDetailsForOfficerResponse:
    return get_farmer_details_for_officer(db, farmer_user_id)

