"""Business logic for Farmer and Agricultural Officer profiles and discovery."""

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.core.constants import UserRole
from app.core.exceptions import DuplicateResourceError, NotFoundError
from app.models.farm import Farm
from app.models.farmer_profile import FarmerProfile
from app.models.officer_profile import OfficerProfile
from app.models.user import User
from app.schemas.auth import UserResponse
from app.schemas.profile import (
    FarmerProfileResponse,
    FarmerProfileUpsert,
    OfficerAvailabilityUpdate,
    OfficerProfileResponse,
    OfficerProfileUpsert,
)

PROFILE_EXCLUDE_USER_FIELDS = {"preferred_language", "full_name", "phone_number"}


def _apply_optional_user_updates(user: User, payload: FarmerProfileUpsert | OfficerProfileUpsert) -> None:
    """Update optional user-level fields shared across profile forms."""
    if payload.preferred_language is not None:
        user.preferred_language = payload.preferred_language
    if payload.full_name is not None:
        user.full_name = payload.full_name
    if payload.phone_number is not None:
        user.phone_number = payload.phone_number


def build_farmer_profile_response(db: Session, profile: FarmerProfile) -> FarmerProfileResponse:
    """Serialize FarmerProfile with user details and total farm count."""
    farms_count = db.scalar(
        select(func.count(Farm.id)).where(Farm.farmer_profile_id == profile.id)
    ) or 0
    return FarmerProfileResponse(
        id=profile.id,
        user_id=profile.user_id,
        village=profile.village,
        taluk_or_block=profile.taluk_or_block,
        district=profile.district,
        state=profile.state,
        pincode=profile.pincode,
        farming_experience_years=profile.farming_experience_years,
        education_level=profile.education_level,
        primary_occupation=profile.primary_occupation,
        bio=profile.bio,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
        user=UserResponse.model_validate(profile.user),
        farms_count=int(farms_count),
    )


def get_farmer_profile(db: Session, user_id: int) -> FarmerProfile:
    """Fetch a FarmerProfile by user_id or raise 404."""
    profile = db.scalar(
        select(FarmerProfile)
        .options(joinedload(FarmerProfile.user))
        .where(FarmerProfile.user_id == user_id)
    )
    if profile is None:
        raise NotFoundError("Farmer profile not found. Please create your profile first.")
    return profile


def create_farmer_profile(
    db: Session, user: User, payload: FarmerProfileUpsert
) -> FarmerProfileResponse:
    """Create a FarmerProfile for the authenticated Farmer."""
    existing = db.scalar(select(FarmerProfile).where(FarmerProfile.user_id == user.id))
    if existing is not None:
        raise DuplicateResourceError("Farmer profile already exists. Use PUT to update it.")

    _apply_optional_user_updates(user, payload)
    profile_data = payload.model_dump(exclude=PROFILE_EXCLUDE_USER_FIELDS)
    profile = FarmerProfile(user_id=user.id, **profile_data)
    db.add(profile)
    db.commit()
    db.refresh(profile)
    db.refresh(user)
    return build_farmer_profile_response(db, profile)


def upsert_farmer_profile(
    db: Session, user: User, payload: FarmerProfileUpsert
) -> FarmerProfileResponse:
    """Create or update the authenticated Farmer's profile."""
    _apply_optional_user_updates(user, payload)
    profile_data = payload.model_dump(exclude=PROFILE_EXCLUDE_USER_FIELDS)

    profile = db.scalar(select(FarmerProfile).where(FarmerProfile.user_id == user.id))
    if profile is None:
        profile = FarmerProfile(user_id=user.id, **profile_data)
        db.add(profile)
    else:
        for field, value in profile_data.items():
            setattr(profile, field, value)

    db.commit()
    db.refresh(profile)
    db.refresh(user)
    return build_farmer_profile_response(db, profile)


def update_user_preferred_language(
    db: Session, user: User, preferred_language: str
) -> UserResponse:
    """Update the authenticated user's preferred language."""
    user.preferred_language = preferred_language
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)


def get_officer_profile(db: Session, user_id: int) -> OfficerProfile:
    """Fetch an OfficerProfile by user_id or raise 404."""
    profile = db.scalar(
        select(OfficerProfile)
        .options(joinedload(OfficerProfile.user))
        .where(OfficerProfile.user_id == user_id)
    )
    if profile is None:
        raise NotFoundError(
            "Agricultural Officer profile not found. Please create your profile first."
        )
    return profile


def create_officer_profile(
    db: Session, user: User, payload: OfficerProfileUpsert
) -> OfficerProfileResponse:
    """Create an OfficerProfile for the authenticated Agricultural Officer."""
    existing = db.scalar(select(OfficerProfile).where(OfficerProfile.user_id == user.id))
    if existing is not None:
        raise DuplicateResourceError("Officer profile already exists. Use PUT to update it.")

    _apply_optional_user_updates(user, payload)
    profile_data = payload.model_dump(exclude=PROFILE_EXCLUDE_USER_FIELDS)
    profile = OfficerProfile(user_id=user.id, **profile_data)
    db.add(profile)
    db.commit()
    db.refresh(profile)
    db.refresh(user)
    return OfficerProfileResponse.model_validate(profile)


def upsert_officer_profile(
    db: Session, user: User, payload: OfficerProfileUpsert
) -> OfficerProfileResponse:
    """Create or update the authenticated Agricultural Officer's profile."""
    _apply_optional_user_updates(user, payload)
    profile_data = payload.model_dump(exclude=PROFILE_EXCLUDE_USER_FIELDS)

    profile = db.scalar(select(OfficerProfile).where(OfficerProfile.user_id == user.id))
    if profile is None:
        profile = OfficerProfile(user_id=user.id, **profile_data)
        db.add(profile)
    else:
        for field, value in profile_data.items():
            setattr(profile, field, value)

    db.commit()
    db.refresh(profile)
    db.refresh(user)
    return OfficerProfileResponse.model_validate(profile)


def update_officer_availability(
    db: Session, user: User, payload: OfficerAvailabilityUpdate
) -> OfficerProfileResponse:
    """Update an Agricultural Officer's availability flag and hours."""
    profile = get_officer_profile(db, user.id)
    profile.is_available = payload.is_available
    if payload.availability_hours is not None:
        profile.availability_hours = payload.availability_hours
    db.commit()
    db.refresh(profile)
    return OfficerProfileResponse.model_validate(profile)


def list_officers(
    db: Session,
    specialization: str | None = None,
    language: str | None = None,
    district: str | None = None,
    state: str | None = None,
    available_only: bool = False,
    search: str | None = None,
) -> list[OfficerProfileResponse]:
    """List active Agricultural Officers with optional filtering for discovery."""
    stmt = (
        select(OfficerProfile)
        .join(OfficerProfile.user)
        .options(joinedload(OfficerProfile.user))
        .where(
            User.is_active.is_(True),
            User.role == UserRole.AGRICULTURAL_OFFICER,
        )
    )

    if specialization:
        stmt = stmt.where(OfficerProfile.specialization.ilike(f"%{specialization.strip()}%"))
    if language:
        lang = f"%{language.strip()}%"
        stmt = stmt.where(
            or_(
                OfficerProfile.languages_spoken.ilike(lang),
                User.preferred_language.ilike(lang),
            )
        )
    if district:
        stmt = stmt.where(OfficerProfile.district.ilike(f"%{district.strip()}%"))
    if state:
        stmt = stmt.where(OfficerProfile.state.ilike(f"%{state.strip()}%"))
    if available_only:
        stmt = stmt.where(OfficerProfile.is_available.is_(True))
    if search:
        term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                User.full_name.ilike(term),
                OfficerProfile.specialization.ilike(term),
                OfficerProfile.designation.ilike(term),
                OfficerProfile.district.ilike(term),
            )
        )

    stmt = stmt.order_by(OfficerProfile.is_available.desc(), OfficerProfile.experience_years.desc())
    officers = db.scalars(stmt).all()
    return [OfficerProfileResponse.model_validate(officer) for officer in officers]


def get_officer_public_profile(db: Session, officer_user_id: int) -> OfficerProfileResponse:
    """Return an active Agricultural Officer's public profile by user_id."""
    profile = db.scalar(
        select(OfficerProfile)
        .join(OfficerProfile.user)
        .options(joinedload(OfficerProfile.user))
        .where(
            OfficerProfile.user_id == officer_user_id,
            User.is_active.is_(True),
            User.role == UserRole.AGRICULTURAL_OFFICER,
        )
    )
    if profile is None:
        raise NotFoundError("Agricultural Officer profile not found.")
    return OfficerProfileResponse.model_validate(profile)

