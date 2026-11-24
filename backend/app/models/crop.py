"""SQLAlchemy ORM model for Crops cultivated on a Farm."""

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.farm import Farm


class Crop(Base):
    """Represents a crop cultivated on a Farm."""

    __tablename__ = "crops"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    farm_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("farms.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    crop_name: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    variety: Mapped[str | None] = mapped_column(String(120), nullable=True)
    season: Mapped[str] = mapped_column(String(80), nullable=False)
    area_acres: Mapped[float] = mapped_column(Float, nullable=False)
    sowing_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    expected_harvest_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    growth_stage: Mapped[str | None] = mapped_column(String(100), nullable=True)
    estimated_yield_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    farm: Mapped["Farm"] = relationship("Farm", back_populates="crops")

