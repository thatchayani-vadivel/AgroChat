"""REST endpoints for Government Schemes, Loans, Insurance, Equipment Rentals, and Services."""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.constants import SchemeCategory
from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.advisory import (
    AgriculturalServiceResponse,
    EquipmentRentalResponse,
    SchemeResponse,
)
from app.services.advisory_service import (
    get_equipment_details,
    get_scheme_details,
    get_service_details,
    list_agricultural_services,
    list_equipment_rentals,
    list_schemes,
)

router = APIRouter(prefix="/api", tags=["Schemes, Equipment & Nearby Services"])


@router.get(
    "/schemes",
    response_model=list[SchemeResponse],
    status_code=status.HTTP_200_OK,
    summary="List Schemes, Subsidies, Loans & Insurance",
    description="Browse government schemes, subsidies, agricultural loans, and crop/livestock insurance.",
)
def read_schemes(
    category: SchemeCategory | None = Query(default=None),
    state: str | None = Query(default=None),
    search: str | None = Query(default=None),
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[SchemeResponse]:
    return list_schemes(db=db, category=category, state=state, search=search)


@router.get(
    "/schemes/{scheme_id}",
    response_model=SchemeResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Scheme Details",
    description="Return full details, eligibility, required documents, and application steps for a scheme.",
)
def read_scheme_detail(
    scheme_id: int,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SchemeResponse:
    return get_scheme_details(db, scheme_id)


@router.get(
    "/equipment-rentals",
    response_model=list[EquipmentRentalResponse],
    status_code=status.HTTP_200_OK,
    summary="List Equipment Rentals",
    description="Browse tractors, harvesters, drones, and farm equipment available for rent.",
)
def read_equipment_rentals(
    category: str | None = Query(default=None),
    district: str | None = Query(default=None),
    state: str | None = Query(default=None),
    available_only: bool = Query(default=False),
    search: str | None = Query(default=None),
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[EquipmentRentalResponse]:
    return list_equipment_rentals(
        db=db,
        category=category,
        district=district,
        state=state,
        available_only=available_only,
        search=search,
    )


@router.get(
    "/equipment-rentals/{equipment_id}",
    response_model=EquipmentRentalResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Equipment Rental Details",
    description="Return detailed pricing, provider contact, and availability for a rental item.",
)
def read_equipment_detail(
    equipment_id: int,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> EquipmentRentalResponse:
    return get_equipment_details(db, equipment_id)


@router.get(
    "/services",
    response_model=list[AgriculturalServiceResponse],
    status_code=status.HTTP_200_OK,
    summary="List Nearby Agricultural Services & Offices",
    description="Find Krishi Vigyan Kendras, soil testing labs, veterinary clinics, and agriculture offices.",
)
def read_agricultural_services(
    service_type: str | None = Query(default=None),
    district: str | None = Query(default=None),
    state: str | None = Query(default=None),
    search: str | None = Query(default=None),
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[AgriculturalServiceResponse]:
    return list_agricultural_services(
        db=db,
        service_type=service_type,
        district=district,
        state=state,
        search=search,
    )


@router.get(
    "/services/{service_id}",
    response_model=AgriculturalServiceResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Agricultural Service Details",
    description="Return contact, address, working hours, and coordinates for an agricultural service center.",
)
def read_service_detail(
    service_id: int,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AgriculturalServiceResponse:
    return get_service_details(db, service_id)

