"""SQLAlchemy ORM model for Livestock and allied agricultural activities."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.farm import Farm


class Livestock(Base):
    """Represents livestock or allied agricultural activity associated with a Farm."""

    __tablename__ = "livestock"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    farm_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("farms.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    category: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    breed_or_type: Mapped[str | None] = mapped_column(String(120), nullable=True)
    count: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1,
        server_default=text("1"),
    )
    purpose: Mapped[str | None] = mapped_column(String(150), nullable=True)
    health_status: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        default="Healthy",
        server_default="Healthy",
    )
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

    farm: Mapped["Farm"] = relationship("Farm", back_populates="livestock")

