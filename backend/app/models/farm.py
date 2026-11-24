"""SQLAlchemy ORM model for Farms owned by Farmers."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.crop import Crop
    from app.models.farmer_profile import FarmerProfile
    from app.models.livestock import Livestock


class Farm(Base):
    """Represents a farm belonging to a FarmerProfile."""

    __tablename__ = "farms"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    farmer_profile_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("farmer_profiles.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    farm_name: Mapped[str] = mapped_column(String(150), nullable=False)
    total_area_acres: Mapped[float] = mapped_column(Float, nullable=False)
    soil_type: Mapped[str] = mapped_column(String(100), nullable=False)
    irrigation_type: Mapped[str] = mapped_column(String(100), nullable=False)
    water_source: Mapped[str | None] = mapped_column(String(120), nullable=True)
    location: Mapped[str] = mapped_column(String(255), nullable=False)
    district: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    state: Mapped[str] = mapped_column(String(120), nullable=False)
    ownership_type: Mapped[str | None] = mapped_column(String(80), nullable=True)
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

    farmer_profile: Mapped["FarmerProfile"] = relationship(
        "FarmerProfile", back_populates="farms"
    )
    crops: Mapped[list["Crop"]] = relationship(
        "Crop",
        back_populates="farm",
        cascade="all, delete-orphan",
        order_by="Crop.id.desc()",
    )
    livestock: Mapped[list["Livestock"]] = relationship(
        "Livestock",
        back_populates="farm",
        cascade="all, delete-orphan",
        order_by="Livestock.id.desc()",
    )

