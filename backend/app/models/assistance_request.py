"""SQLAlchemy ORM model for Farmer agricultural assistance requests."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum as SQLEnum, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.constants import RequestPriority, RequestStatus
from app.db.base import Base

if TYPE_CHECKING:
    from app.models.consultation import Consultation
    from app.models.crop import Crop
    from app.models.farm import Farm
    from app.models.message import Message
    from app.models.request_attachment import RequestAttachment
    from app.models.user import User


class AssistanceRequest(Base):
    """Represents a Farmer's request for agricultural guidance from an Officer."""

    __tablename__ = "assistance_requests"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    farmer_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    officer_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    farm_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("farms.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    crop_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("crops.id", ondelete="SET NULL"),
        nullable=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    category: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    priority: Mapped[RequestPriority] = mapped_column(
        SQLEnum(
            RequestPriority,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="request_priority_enum",
        ),
        nullable=False,
        default=RequestPriority.MEDIUM,
        server_default=RequestPriority.MEDIUM.value,
    )
    status: Mapped[RequestStatus] = mapped_column(
        SQLEnum(
            RequestStatus,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="request_status_enum",
        ),
        nullable=False,
        default=RequestStatus.PENDING,
        server_default=RequestStatus.PENDING.value,
        index=True,
    )
    officer_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
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

    farmer: Mapped["User"] = relationship(
        "User", foreign_keys=[farmer_id], back_populates="submitted_requests"
    )
    officer: Mapped["User | None"] = relationship(
        "User", foreign_keys=[officer_id], back_populates="assigned_requests"
    )
    farm: Mapped["Farm | None"] = relationship("Farm")
    crop: Mapped["Crop | None"] = relationship("Crop")
    consultation: Mapped["Consultation | None"] = relationship(
        "Consultation",
        back_populates="request",
        uselist=False,
        cascade="all, delete-orphan",
    )
    messages: Mapped[list["Message"]] = relationship(
        "Message",
        back_populates="request",
        cascade="all, delete-orphan",
        order_by="Message.created_at.asc(), Message.id.asc()",
    )
    attachments: Mapped[list["RequestAttachment"]] = relationship(
        "RequestAttachment",
        back_populates="request",
        cascade="all, delete-orphan",
    )

