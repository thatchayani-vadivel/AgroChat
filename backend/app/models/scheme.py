"""SQLAlchemy ORM model for government schemes, subsidies, loans, and insurance."""

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, Integer, String, Text, func, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.constants import SchemeCategory
from app.db.base import Base


class Scheme(Base):
    """Represents agricultural schemes, subsidies, loans, and insurance programs."""

    __tablename__ = "schemes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(220), nullable=False)
    category: Mapped[SchemeCategory] = mapped_column(
        SQLEnum(
            SchemeCategory,
            values_callable=lambda enum_cls: [member.value for member in enum_cls],
            name="scheme_category_enum",
        ),
        nullable=False,
        index=True,
    )
    provider: Mapped[str] = mapped_column(String(180), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    benefits: Mapped[str] = mapped_column(Text, nullable=False)
    eligibility: Mapped[str] = mapped_column(Text, nullable=False)
    required_documents: Mapped[str | None] = mapped_column(Text, nullable=True)
    application_process: Mapped[str | None] = mapped_column(Text, nullable=True)
    official_link: Mapped[str | None] = mapped_column(String(300), nullable=True)
    state: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
        default="All India",
        server_default="All India",
        index=True,
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

