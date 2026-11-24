"""SQLAlchemy User ORM model for Farmers and Agricultural Officers."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, Integer, String, func, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.constants import UserRole
from app.db.base import Base

if TYPE_CHECKING:
    from app.models.assistance_request import AssistanceRequest
    from app.models.farmer_profile import FarmerProfile
    from app.models.notification import Notification
    from app.models.officer_profile import OfficerProfile


class User(Base):
    """Represents a registered AgroChat user (Farmer or Agricultural Officer)."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    phone_number: Mapped[str] = mapped_column(String(20), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(
            UserRole,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="user_role_enum",
        ),
        nullable=False,
        index=True,
    )
    preferred_language: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="English",
        server_default="English",
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("1"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    farmer_profile: Mapped["FarmerProfile | None"] = relationship(
        "FarmerProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    officer_profile: Mapped["OfficerProfile | None"] = relationship(
        "OfficerProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    submitted_requests: Mapped[list["AssistanceRequest"]] = relationship(
        "AssistanceRequest",
        foreign_keys="AssistanceRequest.farmer_id",
        back_populates="farmer",
        cascade="all, delete-orphan",
    )
    assigned_requests: Mapped[list["AssistanceRequest"]] = relationship(
        "AssistanceRequest",
        foreign_keys="AssistanceRequest.officer_id",
        back_populates="officer",
    )
    notifications: Mapped[list["Notification"]] = relationship(
        "Notification",
        back_populates="user",
        cascade="all, delete-orphan",
    )

