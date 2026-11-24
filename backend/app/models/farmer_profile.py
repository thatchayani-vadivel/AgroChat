"""SQLAlchemy ORM model for Farmer profiles."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.farm import Farm
    from app.models.user import User


class FarmerProfile(Base):
    """Extended profile details for a user with the Farmer role."""

    __tablename__ = "farmer_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    village: Mapped[str | None] = mapped_column(String(120), nullable=True)
    taluk_or_block: Mapped[str | None] = mapped_column(String(120), nullable=True)
    district: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    state: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    pincode: Mapped[str | None] = mapped_column(String(12), nullable=True)
    farming_experience_years: Mapped[int | None] = mapped_column(Integer, nullable=True)
    education_level: Mapped[str | None] = mapped_column(String(100), nullable=True)
    primary_occupation: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
        default="Farming",
        server_default="Farming",
    )
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
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

    user: Mapped["User"] = relationship("User", back_populates="farmer_profile")
    farms: Mapped[list["Farm"]] = relationship(
        "Farm",
        back_populates="farmer_profile",
        cascade="all, delete-orphan",
        order_by="Farm.id.desc()",
    )

