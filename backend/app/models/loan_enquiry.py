"""SQLAlchemy ORM models for Farmer Loan Enquiries and Supporting Documents."""

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.scheme import Scheme
    from app.models.user import User


class LoanEnquiry(Base):
    """Represents an agricultural credit/loan advisory enquiry submitted by a Farmer."""

    __tablename__ = "loan_enquiries"

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
    loan_type: Mapped[str] = mapped_column(String(100), nullable=False)
    preferred_bank: Mapped[str | None] = mapped_column(String(150), nullable=True)
    requested_amount_inr: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    purpose: Mapped[str] = mapped_column(Text, nullable=False)
    annual_income_inr: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    land_holding_acres: Mapped[Decimal | None] = mapped_column(Numeric(8, 2), nullable=True)
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
    documents: Mapped[list["LoanDocument"]] = relationship(
        "LoanDocument",
        back_populates="enquiry",
        cascade="all, delete-orphan",
    )


class LoanDocument(Base):
    """Represents a supporting KYC or land record uploaded for a loan enquiry."""

    __tablename__ = "loan_documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    enquiry_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("loan_enquiries.id", ondelete="CASCADE"),
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

    enquiry: Mapped["LoanEnquiry"] = relationship("LoanEnquiry", back_populates="documents")
