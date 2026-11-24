"""SQLAlchemy ORM model for agricultural equipment rentals."""

from datetime import datetime

from sqlalchemy import DateTime, Enum as SQLEnum, Float, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.constants import EquipmentAvailability
from app.db.base import Base


class EquipmentRental(Base):
    """Represents agricultural machinery and equipment available for rent."""

    __tablename__ = "equipment_rentals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    equipment_name: Mapped[str] = mapped_column(String(180), nullable=False)
    category: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    provider_name: Mapped[str] = mapped_column(String(150), nullable=False)
    contact_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    location: Mapped[str] = mapped_column(String(220), nullable=False)
    district: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    state: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    daily_rate_inr: Mapped[float] = mapped_column(Float, nullable=False)
    hourly_rate_inr: Mapped[float | None] = mapped_column(Float, nullable=True)
    availability_status: Mapped[EquipmentAvailability] = mapped_column(
        SQLEnum(
            EquipmentAvailability,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="equipment_availability_enum",
        ),
        nullable=False,
        default=EquipmentAvailability.AVAILABLE,
        server_default=EquipmentAvailability.AVAILABLE.value,
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

