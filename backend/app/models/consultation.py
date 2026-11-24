"""SQLAlchemy ORM model for Farmer–Officer Consultations."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum as SQLEnum, ForeignKey, Integer, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.constants import ConsultationStatus
from app.db.base import Base

if TYPE_CHECKING:
    from app.models.assistance_request import AssistanceRequest
    from app.models.user import User


class Consultation(Base):
    """Tracks an accepted advisory consultation between a Farmer and an Officer."""

    __tablename__ = "consultations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    request_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("assistance_requests.id", ondelete="CASCADE"),
        unique=True,
        index=True,
        nullable=False,
    )
    farmer_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    officer_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    status: Mapped[ConsultationStatus] = mapped_column(
        SQLEnum(
            ConsultationStatus,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="consultation_status_enum",
        ),
        nullable=False,
        default=ConsultationStatus.ACTIVE,
        server_default=ConsultationStatus.ACTIVE.value,
        index=True,
    )
    guidance_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    recommendations: Mapped[str | None] = mapped_column(Text, nullable=True)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    request: Mapped["AssistanceRequest"] = relationship(
        "AssistanceRequest", back_populates="consultation"
    )
    farmer: Mapped["User"] = relationship("User", foreign_keys=[farmer_id])
    officer: Mapped["User"] = relationship("User", foreign_keys=[officer_id])

