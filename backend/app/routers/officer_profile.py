"""REST endpoints for Agricultural Officer profiles and Officer discovery."""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_officer, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.profile import (
    OfficerAvailabilityUpdate,
    OfficerProfileResponse,
    OfficerProfileUpsert,
)
from app.services.profile_service import (
    create_officer_profile,
    get_officer_profile,
    get_officer_public_profile,
    list_officers,
    update_officer_availability,
    upsert_officer_profile,
)

router = APIRouter(prefix="/api/officers", tags=["Agricultural Officer Profile & Discovery"])


@router.get(
    "/profile",
    response_model=OfficerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get My Officer Profile",
    description="Return the authenticated Agricultural Officer's profile.",
)
def read_my_officer_profile(
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> OfficerProfileResponse:
    profile = get_officer_profile(db, current_officer.id)
    return OfficerProfileResponse.model_validate(profile)


@router.post(
    "/profile",
    response_model=OfficerProfileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Officer Profile",
    description="Create a profile for the authenticated Agricultural Officer.",
)
def create_my_officer_profile(
    payload: OfficerProfileUpsert,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> OfficerProfileResponse:
    return create_officer_profile(db, current_officer, payload)


@router.put(
    "/profile",
    response_model=OfficerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Create or Update Officer Profile",
    description="Create or update specialization, languages spoken, location, and availability.",
)
def update_my_officer_profile(
    payload: OfficerProfileUpsert,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> OfficerProfileResponse:
    return upsert_officer_profile(db, current_officer, payload)


@router.patch(
    "/availability",
    response_model=OfficerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Officer Availability",
    description="Toggle availability status and update consultation hours for the authenticated Officer.",
)
def patch_my_availability(
    payload: OfficerAvailabilityUpdate,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> OfficerProfileResponse:
    return update_officer_availability(db, current_officer, payload)


@router.get(
    "",
    response_model=list[OfficerProfileResponse],
    status_code=status.HTTP_200_OK,
    summary="Discover Agricultural Officers",
    description="Search and filter active Agricultural Officers by specialization, language, district, or availability.",
)
def discover_officers(
    specialization: str | None = Query(default=None, description="Filter by specialization"),
    language: str | None = Query(default=None, description="Filter by spoken/preferred language"),
    district: str | None = Query(default=None, description="Filter by district"),
    state: str | None = Query(default=None, description="Filter by state"),
    available_only: bool = Query(default=False, description="Show only currently available officers"),
    search: str | None = Query(default=None, description="Keyword search across name, designation, specialization"),
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[OfficerProfileResponse]:
    return list_officers(
        db=db,
        specialization=specialization,
        language=language,
        district=district,
        state=state,
        available_only=available_only,
        search=search,
    )


@router.get(
    "/{officer_user_id}",
    response_model=OfficerProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Agricultural Officer Details",
    description="Return an Agricultural Officer's public profile details.",
)
def read_officer_public_profile(
    officer_user_id: int,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OfficerProfileResponse:
    return get_officer_public_profile(db, officer_user_id)

