"""Business logic for Farmer Equipment Rental Bookings."""

from decimal import Decimal
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AuthorizationError, NotFoundError
from app.models.equipment_rental import EquipmentRental
from app.models.rental_booking import RentalBooking
from app.models.user import User
from app.schemas.rental_booking import RentalBookingCreate, RentalBookingStatusUpdate


def create_rental_booking(
    db: Session,
    current_farmer: User,
    payload: RentalBookingCreate,
) -> RentalBooking:
    """Submit a booking request for farm equipment (tractor, drone, harvester, etc.)."""
    equipment = db.get(EquipmentRental, payload.equipment_id)
    if not equipment:
        raise NotFoundError("Equipment rental item not found.")

    # Calculate total cost based on daily or hourly rate
    if payload.rental_type == "hourly" and equipment.hourly_rate_inr:
        unit_rate = Decimal(str(equipment.hourly_rate_inr))
    elif equipment.daily_rate_inr:
        unit_rate = Decimal(str(equipment.daily_rate_inr))
    else:
        unit_rate = Decimal("1000.00")

    total_cost = unit_rate * Decimal(payload.duration_units)

    booking = RentalBooking(
        equipment_id=payload.equipment_id,
        farmer_id=current_farmer.id,
        start_date=payload.start_date,
        end_date=payload.end_date,
        rental_type=payload.rental_type,
        duration_units=payload.duration_units,
        total_cost_inr=total_cost,
        delivery_location=payload.delivery_location,
        contact_phone=payload.contact_phone,
        booking_status="requested",
        farmer_notes=payload.farmer_notes,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def list_farmer_rental_bookings(db: Session, current_farmer: User) -> list[RentalBooking]:
    """List rental booking requests made by the authenticated Farmer."""
    stmt = (
        select(RentalBooking)
        .where(RentalBooking.farmer_id == current_farmer.id)
        .order_by(RentalBooking.id.desc())
    )
    return list(db.scalars(stmt).all())


def list_all_rental_bookings_for_officers(db: Session) -> list[RentalBooking]:
    """List rental bookings for Agricultural Officers to oversee and assist."""
    stmt = select(RentalBooking).order_by(RentalBooking.id.desc())
    return list(db.scalars(stmt).all())


def get_rental_booking_details(
    db: Session,
    booking_id: int,
    current_user: User,
) -> RentalBooking:
    """Get details of an equipment booking."""
    booking = db.get(RentalBooking, booking_id)
    if not booking:
        raise NotFoundError("Rental booking not found.")

    if current_user.role.value == "farmer" and booking.farmer_id != current_user.id:
        raise AuthorizationError("You do not have permission to view this booking.")

    return booking


def cancel_rental_booking(
    db: Session,
    booking_id: int,
    current_farmer: User,
) -> RentalBooking:
    """Allow Farmer to cancel their requested booking."""
    booking = db.get(RentalBooking, booking_id)
    if not booking:
        raise NotFoundError("Rental booking not found.")

    if booking.farmer_id != current_farmer.id:
        raise AuthorizationError("You do not own this booking.")

    if booking.booking_status not in ("requested", "confirmed"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel booking in '{booking.booking_status}' status.",
        )

    booking.booking_status = "cancelled"
    db.commit()
    db.refresh(booking)
    return booking


def update_rental_booking_status(
    db: Session,
    booking_id: int,
    _current_officer: User,
    payload: RentalBookingStatusUpdate,
) -> RentalBooking:
    """Allow Agricultural Officer to update equipment booking status and response."""
    booking = db.get(RentalBooking, booking_id)
    if not booking:
        raise NotFoundError("Rental booking not found.")

    booking.booking_status = payload.booking_status
    if payload.provider_response:
        booking.provider_response = payload.provider_response

    db.commit()
    db.refresh(booking)
    return booking
