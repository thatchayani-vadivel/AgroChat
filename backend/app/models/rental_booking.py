"""SQLAlchemy ORM model for Farmer Equipment Rental Bookings."""

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.equipment_rental import EquipmentRental
    from app.models.user import User


class RentalBooking(Base):
    """Represents a Farmer's booking request for agricultural machinery (tractor, rotavator, etc.)."""

    __tablename__ = "rental_bookings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    equipment_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("equipment_rentals.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    farmer_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="RESTRICT"),
        index=True,
        nullable=False,
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    rental_type: Mapped[str] = mapped_column(String(20), nullable=False)  # 'daily' or 'hourly'
    duration_units: Mapped[int] = mapped_column(Integer, nullable=False)
    total_cost_inr: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    delivery_location: Mapped[str] = mapped_column(String(255), nullable=False)
    contact_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    booking_status: Mapped[str] = mapped_column(
        String(50),
        default="requested",
        server_default="requested",
        index=True,
        nullable=False,
    )
    farmer_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    provider_response: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    equipment: Mapped["EquipmentRental"] = relationship("EquipmentRental")
    farmer: Mapped["User"] = relationship("User")
