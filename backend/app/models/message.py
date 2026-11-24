"""SQLAlchemy ORM model for Farmer–Officer chat and voice messages."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, ForeignKey, Integer, String, Text, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.constants import MessageType
from app.db.base import Base

if TYPE_CHECKING:
    from app.models.assistance_request import AssistanceRequest
    from app.models.user import User


class Message(Base):
    """Represents a text or voice message exchanged inside an assistance request."""

    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    request_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("assistance_requests.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    sender_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    receiver_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    message_type: Mapped[MessageType] = mapped_column(
        SQLEnum(
            MessageType,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="message_type_enum",
        ),
        nullable=False,
        default=MessageType.TEXT,
        server_default=MessageType.TEXT.value,
    )
    content: Mapped[str | None] = mapped_column(Text, nullable=True)
    audio_file_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    audio_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    duration_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_read: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("0"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )

    request: Mapped["AssistanceRequest"] = relationship(
        "AssistanceRequest", back_populates="messages"
    )
    sender: Mapped["User"] = relationship("User", foreign_keys=[sender_id])
    receiver: Mapped["User"] = relationship("User", foreign_keys=[receiver_id])

