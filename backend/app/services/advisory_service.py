"""Business logic for Government Schemes, Loans, Insurance, Equipment Rentals, and Services."""

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.constants import EquipmentAvailability, SchemeCategory
from app.core.exceptions import NotFoundError
from app.models.agricultural_service import AgriculturalService
from app.models.equipment_rental import EquipmentRental
from app.models.scheme import Scheme
from app.schemas.advisory import (
    AgriculturalServiceResponse,
    EquipmentRentalResponse,
    SchemeResponse,
)


def list_schemes(
    db: Session,
    category: SchemeCategory | None = None,
    state: str | None = None,
    search: str | None = None,
) -> list[SchemeResponse]:
    """Query active schemes, subsidies, agricultural loans, and insurance programs."""
    stmt = select(Scheme).where(Scheme.is_active.is_(True))
    if category is not None:
        stmt = stmt.where(Scheme.category == category)
    if state:
        cleaned_state = state.strip()
        stmt = stmt.where(
            or_(
                Scheme.state.ilike(f"%{cleaned_state}%"),
                Scheme.state.ilike("All India"),
            )
        )
    if search:
        term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                Scheme.title.ilike(term),
                Scheme.description.ilike(term),
                Scheme.benefits.ilike(term),
                Scheme.provider.ilike(term),
            )
        )
    stmt = stmt.order_by(Scheme.category.asc(), Scheme.id.asc())
    return [SchemeResponse.model_validate(item) for item in db.scalars(stmt).all()]


def get_scheme_details(db: Session, scheme_id: int) -> SchemeResponse:
    """Return a single scheme/subsidy/loan/insurance record by ID."""
    scheme = db.scalar(
        select(Scheme).where(Scheme.id == scheme_id, Scheme.is_active.is_(True))
    )
    if scheme is None:
        raise NotFoundError("Scheme or financial program not found.")
    return SchemeResponse.model_validate(scheme)


def list_equipment_rentals(
    db: Session,
    category: str | None = None,
    district: str | None = None,
    state: str | None = None,
    available_only: bool = False,
    search: str | None = None,
) -> list[EquipmentRentalResponse]:
    """Query agricultural equipment rentals with optional filters."""
    stmt = select(EquipmentRental)
    if category:
        stmt = stmt.where(EquipmentRental.category.ilike(f"%{category.strip()}%"))
    if district:
        stmt = stmt.where(EquipmentRental.district.ilike(f"%{district.strip()}%"))
    if state:
        stmt = stmt.where(EquipmentRental.state.ilike(f"%{state.strip()}%"))
    if available_only:
        stmt = stmt.where(EquipmentRental.availability_status == EquipmentAvailability.AVAILABLE)
    if search:
        term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                EquipmentRental.equipment_name.ilike(term),
                EquipmentRental.description.ilike(term),
                EquipmentRental.provider_name.ilike(term),
                EquipmentRental.location.ilike(term),
            )
        )
    stmt = stmt.order_by(EquipmentRental.availability_status.asc(), EquipmentRental.id.asc())
    return [EquipmentRentalResponse.model_validate(item) for item in db.scalars(stmt).all()]


def get_equipment_details(db: Session, equipment_id: int) -> EquipmentRentalResponse:
    """Return a single equipment rental record by ID."""
    item = db.get(EquipmentRental, equipment_id)
    if item is None:
        raise NotFoundError("Equipment rental entry not found.")
    return EquipmentRentalResponse.model_validate(item)


def list_agricultural_services(
    db: Session,
    service_type: str | None = None,
    district: str | None = None,
    state: str | None = None,
    search: str | None = None,
) -> list[AgriculturalServiceResponse]:
    """Query nearby agricultural offices, KVKs, soil labs, and allied services."""
    stmt = select(AgriculturalService)
    if service_type:
        stmt = stmt.where(AgriculturalService.service_type.ilike(f"%{service_type.strip()}%"))
    if district:
        stmt = stmt.where(AgriculturalService.district.ilike(f"%{district.strip()}%"))
    if state:
        stmt = stmt.where(AgriculturalService.state.ilike(f"%{state.strip()}%"))
    if search:
        term = f"%{search.strip()}%"
        stmt = stmt.where(
            or_(
                AgriculturalService.name.ilike(term),
                AgriculturalService.service_type.ilike(term),
                AgriculturalService.description.ilike(term),
                AgriculturalService.address.ilike(term),
            )
        )
    stmt = stmt.order_by(AgriculturalService.id.asc())
    return [AgriculturalServiceResponse.model_validate(item) for item in db.scalars(stmt).all()]


def get_service_details(db: Session, service_id: int) -> AgriculturalServiceResponse:
    """Return a single agricultural service/office record by ID."""
    item = db.get(AgriculturalService, service_id)
    if item is None:
        raise NotFoundError("Agricultural service center not found.")
    return AgriculturalServiceResponse.model_validate(item)

