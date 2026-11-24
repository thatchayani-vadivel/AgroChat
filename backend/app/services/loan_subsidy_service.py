"""Business logic for Farmer Loan and Subsidy enquiries and Officer guidance."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AuthorizationError, NotFoundError
from app.models.loan_enquiry import LoanEnquiry
from app.models.subsidy_enquiry import SubsidyEnquiry
from app.models.user import User
from app.schemas.loan import LoanEnquiryCreate, LoanEnquiryGuidanceUpdate
from app.schemas.subsidy import SubsidyEnquiryCreate, SubsidyEnquiryGuidanceUpdate


# ==================== LOAN ENQUIRIES ====================

def create_loan_enquiry(db: Session, current_farmer: User, payload: LoanEnquiryCreate) -> LoanEnquiry:
    """Submit a new agricultural loan advisory enquiry."""
    enquiry = LoanEnquiry(
        farmer_id=current_farmer.id,
        scheme_id=payload.scheme_id,
        loan_type=payload.loan_type,
        preferred_bank=payload.preferred_bank,
        requested_amount_inr=payload.requested_amount_inr,
        purpose=payload.purpose,
        annual_income_inr=payload.annual_income_inr,
        land_holding_acres=payload.land_holding_acres,
        status="submitted",
    )
    db.add(enquiry)
    db.commit()
    db.refresh(enquiry)
    return enquiry


def list_farmer_loan_enquiries(db: Session, current_farmer: User) -> list[LoanEnquiry]:
    """List loan enquiries submitted by the authenticated Farmer."""
    stmt = (
        select(LoanEnquiry)
        .where(LoanEnquiry.farmer_id == current_farmer.id)
        .order_by(LoanEnquiry.id.desc())
    )
    return list(db.scalars(stmt).all())


def list_all_loan_enquiries_for_officers(db: Session) -> list[LoanEnquiry]:
    """List open or all loan enquiries for Agricultural Officers to provide advisory."""
    stmt = select(LoanEnquiry).order_by(LoanEnquiry.id.desc())
    return list(db.scalars(stmt).all())


def get_loan_enquiry_details(db: Session, enquiry_id: int, current_user: User) -> LoanEnquiry:
    """Get details of a loan enquiry."""
    enquiry = db.get(LoanEnquiry, enquiry_id)
    if not enquiry:
        raise NotFoundError("Loan enquiry not found.")

    # Access check: Owning farmer or any Agricultural Officer
    if current_user.role.value == "farmer" and enquiry.farmer_id != current_user.id:
        raise AuthorizationError("You do not have permission to view this loan enquiry.")

    return enquiry


def officer_review_loan_enquiry(
    db: Session,
    enquiry_id: int,
    _current_officer: User,
    payload: LoanEnquiryGuidanceUpdate,
) -> LoanEnquiry:
    """Provide advisory guidance on a Farmer's loan enquiry."""
    enquiry = db.get(LoanEnquiry, enquiry_id)
    if not enquiry:
        raise NotFoundError("Loan enquiry not found.")

    enquiry.status = payload.status
    enquiry.officer_guidance = payload.officer_guidance
    db.commit()
    db.refresh(enquiry)
    return enquiry


# ==================== SUBSIDY ENQUIRIES ====================

def create_subsidy_enquiry(db: Session, current_farmer: User, payload: SubsidyEnquiryCreate) -> SubsidyEnquiry:
    """Submit a government subsidy advisory enquiry."""
    enquiry = SubsidyEnquiry(
        farmer_id=current_farmer.id,
        scheme_id=payload.scheme_id,
        farm_id=payload.farm_id,
        subsidy_title=payload.subsidy_title,
        enquiry_details=payload.enquiry_details,
        status="submitted",
    )
    db.add(enquiry)
    db.commit()
    db.refresh(enquiry)
    return enquiry


def list_farmer_subsidy_enquiries(db: Session, current_farmer: User) -> list[SubsidyEnquiry]:
    """List subsidy enquiries submitted by the authenticated Farmer."""
    stmt = (
        select(SubsidyEnquiry)
        .where(SubsidyEnquiry.farmer_id == current_farmer.id)
        .order_by(SubsidyEnquiry.id.desc())
    )
    return list(db.scalars(stmt).all())


def list_all_subsidy_enquiries_for_officers(db: Session) -> list[SubsidyEnquiry]:
    """List subsidy enquiries for Agricultural Officers to provide advisory."""
    stmt = select(SubsidyEnquiry).order_by(SubsidyEnquiry.id.desc())
    return list(db.scalars(stmt).all())


def get_subsidy_enquiry_details(db: Session, enquiry_id: int, current_user: User) -> SubsidyEnquiry:
    """Get details of a subsidy enquiry."""
    enquiry = db.get(SubsidyEnquiry, enquiry_id)
    if not enquiry:
        raise NotFoundError("Subsidy enquiry not found.")

    if current_user.role.value == "farmer" and enquiry.farmer_id != current_user.id:
        raise AuthorizationError("You do not have permission to view this subsidy enquiry.")

    return enquiry


def officer_review_subsidy_enquiry(
    db: Session,
    enquiry_id: int,
    _current_officer: User,
    payload: SubsidyEnquiryGuidanceUpdate,
) -> SubsidyEnquiry:
    """Provide advisory guidance on a Farmer's subsidy enquiry."""
    enquiry = db.get(SubsidyEnquiry, enquiry_id)
    if not enquiry:
        raise NotFoundError("Subsidy enquiry not found.")

    enquiry.status = payload.status
    enquiry.officer_guidance = payload.officer_guidance
    db.commit()
    db.refresh(enquiry)
    return enquiry
