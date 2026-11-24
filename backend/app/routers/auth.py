"""Authentication REST endpoints for Farmers and Agricultural Officers."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.constants import UserRole
from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    AuthTokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)
from app.services.auth_service import authenticate_user, register_user

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post(
    "/register/farmer",
    response_model=AuthTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register Farmer",
    description="Create a new Farmer account and return a JWT access token.",
)
def register_farmer(
    payload: UserRegisterRequest,
    db: Session = Depends(get_db),
) -> AuthTokenResponse:
    """Register a new user with the Farmer role."""
    return register_user(db=db, payload=payload, role=UserRole.FARMER)


@router.post(
    "/login/farmer",
    response_model=AuthTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Farmer Login",
    description="Authenticate a Farmer account and return a JWT access token.",
)
def login_farmer(
    payload: UserLoginRequest,
    db: Session = Depends(get_db),
) -> AuthTokenResponse:
    """Authenticate an existing Farmer user."""
    return authenticate_user(db=db, payload=payload, expected_role=UserRole.FARMER)


@router.post(
    "/register/officer",
    response_model=AuthTokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register Agricultural Officer",
    description="Create a new Agricultural Officer account and return a JWT access token.",
)
def register_officer(
    payload: UserRegisterRequest,
    db: Session = Depends(get_db),
) -> AuthTokenResponse:
    """Register a new user with the Agricultural Officer role."""
    return register_user(db=db, payload=payload, role=UserRole.AGRICULTURAL_OFFICER)


@router.post(
    "/login/officer",
    response_model=AuthTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Agricultural Officer Login",
    description="Authenticate an Agricultural Officer account and return a JWT access token.",
)
def login_officer(
    payload: UserLoginRequest,
    db: Session = Depends(get_db),
) -> AuthTokenResponse:
    """Authenticate an existing Agricultural Officer user."""
    return authenticate_user(
        db=db,
        payload=payload,
        expected_role=UserRole.AGRICULTURAL_OFFICER,
    )


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Current Authenticated User",
    description="Return the profile details of the currently authenticated Farmer or Officer.",
)
def get_me(current_user: User = Depends(get_current_user)) -> UserResponse:
    """Return the authenticated user's profile without sensitive fields."""
    return UserResponse.model_validate(current_user)

