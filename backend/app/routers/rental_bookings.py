"""REST endpoints for Equipment Rental Bookings."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer, get_current_officer, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.rental_booking import (
    RentalBookingCreate,
    RentalBookingResponse,
    RentalBookingStatusUpdate,
)
from app.services.rental_booking_service import (
    cancel_rental_booking,
    create_rental_booking,
    get_rental_booking_details,
    list_all_rental_bookings_for_officers,
    list_farmer_rental_bookings,
    update_rental_booking_status,
)

router = APIRouter(prefix="/api/equipment-rentals", tags=["Equipment Rental Bookings"])


@router.post(
    "/bookings",
    response_model=RentalBookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Request Equipment Booking (Farmer)",
    description="Submit a booking request for farm equipment (Tractor, Drone, Harvester, etc.).",
)
def submit_booking_request(
    payload: RentalBookingCreate,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> RentalBookingResponse:
    booking = create_rental_booking(db, current_farmer, payload)
    res = RentalBookingResponse.model_validate(booking)
    if booking.equipment:
        res.equipment_name = booking.equipment.equipment_name
    return res


@router.get(
    "/bookings/my",
    response_model=list[RentalBookingResponse],
    status_code=status.HTTP_200_OK,
    summary="Track My Equipment Bookings (Farmer)",
    description="List all equipment bookings requested by the authenticated Farmer.",
)
def read_my_bookings(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> list[RentalBookingResponse]:
    bookings = list_farmer_rental_bookings(db, current_farmer)
    responses = []
    for b in bookings:
        r = RentalBookingResponse.model_validate(b)
        if b.equipment:
            r.equipment_name = b.equipment.equipment_name
        responses.append(r)
    return responses


@router.get(
    "/bookings",
    response_model=list[RentalBookingResponse],
    status_code=status.HTTP_200_OK,
    summary="List All Equipment Bookings (Officer)",
    description="Allow Agricultural Officers to view equipment rental bookings across farmers.",
)
def read_all_bookings(
    _current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> list[RentalBookingResponse]:
    bookings = list_all_rental_bookings_for_officers(db)
    responses = []
    for b in bookings:
        r = RentalBookingResponse.model_validate(b)
        if b.equipment:
            r.equipment_name = b.equipment.equipment_name
        responses.append(r)
    return responses


@router.get(
    "/bookings/{booking_id}",
    response_model=RentalBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Booking Details",
    description="View details of an equipment booking request.",
)
def read_booking_detail(
    booking_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> RentalBookingResponse:
    booking = get_rental_booking_details(db, booking_id, current_user)
    res = RentalBookingResponse.model_validate(booking)
    if booking.equipment:
        res.equipment_name = booking.equipment.equipment_name
    return res


@router.patch(
    "/bookings/{booking_id}/cancel",
    response_model=RentalBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel Equipment Booking (Farmer)",
    description="Allow a Farmer to cancel their requested equipment booking.",
)
def cancel_booking(
    booking_id: int,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> RentalBookingResponse:
    booking = cancel_rental_booking(db, booking_id, current_farmer)
    res = RentalBookingResponse.model_validate(booking)
    if booking.equipment:
        res.equipment_name = booking.equipment.equipment_name
    return res


@router.patch(
    "/bookings/{booking_id}/status",
    response_model=RentalBookingResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Booking Status (Officer)",
    description="Allow Agricultural Officer to update equipment booking status.",
)
def update_booking_status(
    booking_id: int,
    payload: RentalBookingStatusUpdate,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> RentalBookingResponse:
    booking = update_rental_booking_status(db, booking_id, current_officer, payload)
    res = RentalBookingResponse.model_validate(booking)
    if booking.equipment:
        res.equipment_name = booking.equipment.equipment_name
    return res
