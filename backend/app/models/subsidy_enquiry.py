"""SQLAlchemy ORM models for Government Subsidy Enquiries and Supporting Documents."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.farm import Farm
    from app.models.scheme import Scheme
    from app.models.user import User


class SubsidyEnquiry(Base):
    """Represents a Farmer's application assistance enquiry for government agricultural subsidies."""

    __tablename__ = "subsidy_enquiries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    farmer_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    scheme_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("schemes.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    subsidy_title: Mapped[str] = mapped_column(String(200), nullable=False)
    farm_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("farms.id", ondelete="SET NULL"),
        nullable=True,
    )
    enquiry_details: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(
        String(50),
        default="submitted",
        server_default="submitted",
        index=True,
        nullable=False,
    )
    officer_guidance: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    farmer: Mapped["User"] = relationship("User")
    scheme: Mapped["Scheme | None"] = relationship("Scheme")
    farm: Mapped["Farm | None"] = relationship("Farm")
    documents: Mapped[list["SubsidyDocument"]] = relationship(
        "SubsidyDocument",
        back_populates="enquiry",
        cascade="all, delete-orphan",
    )


class SubsidyDocument(Base):
    """Represents supporting documentation uploaded for a subsidy enquiry."""

    __tablename__ = "subsidy_documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    enquiry_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("subsidy_enquiries.id", ondelete="CASCADE"),
        index=True,
        nullable=False,
    )
    document_name: Mapped[str] = mapped_column(String(150), nullable=False)
    document_type: Mapped[str] = mapped_column(String(100), nullable=False)
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    file_size_bytes: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    enquiry: Mapped["SubsidyEnquiry"] = relationship("SubsidyEnquiry", back_populates="documents")
