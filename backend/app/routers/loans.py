"""REST endpoints for Agricultural Loan Enquiries and Guidance."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer, get_current_officer, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.loan import (
    LoanEnquiryCreate,
    LoanEnquiryGuidanceUpdate,
    LoanEnquiryResponse,
)
from app.services.loan_subsidy_service import (
    create_loan_enquiry,
    get_loan_enquiry_details,
    list_all_loan_enquiries_for_officers,
    list_farmer_loan_enquiries,
    officer_review_loan_enquiry,
)

router = APIRouter(prefix="/api/loans", tags=["Agricultural Loans & Insurance"])


@router.post(
    "/enquiries",
    response_model=LoanEnquiryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit Loan Advisory Enquiry (Farmer)",
    description="Submit an enquiry for agricultural credit/loan guidance.",
)
def submit_loan_enquiry(
    payload: LoanEnquiryCreate,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> LoanEnquiryResponse:
    enquiry = create_loan_enquiry(db, current_farmer, payload)
    return LoanEnquiryResponse.model_validate(enquiry)


@router.get(
    "/enquiries/my",
    response_model=list[LoanEnquiryResponse],
    status_code=status.HTTP_200_OK,
    summary="Track My Loan Enquiries (Farmer)",
    description="List all loan enquiries submitted by the authenticated Farmer.",
)
def read_my_loan_enquiries(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> list[LoanEnquiryResponse]:
    enquiries = list_farmer_loan_enquiries(db, current_farmer)
    return [LoanEnquiryResponse.model_validate(e) for e in enquiries]


@router.get(
    "/enquiries",
    response_model=list[LoanEnquiryResponse],
    status_code=status.HTTP_200_OK,
    summary="List All Loan Enquiries (Officer)",
    description="Allow Agricultural Officers to view loan enquiries across farmers.",
)
def read_all_loan_enquiries(
    _current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> list[LoanEnquiryResponse]:
    enquiries = list_all_loan_enquiries_for_officers(db)
    return [LoanEnquiryResponse.model_validate(e) for e in enquiries]


@router.get(
    "/enquiries/{enquiry_id}",
    response_model=LoanEnquiryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Loan Enquiry Details",
    description="View details of a loan enquiry (owning Farmer or Agricultural Officer).",
)
def read_loan_enquiry_detail(
    enquiry_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> LoanEnquiryResponse:
    enquiry = get_loan_enquiry_details(db, enquiry_id, current_user)
    return LoanEnquiryResponse.model_validate(enquiry)


@router.patch(
    "/enquiries/{enquiry_id}/guidance",
    response_model=LoanEnquiryResponse,
    status_code=status.HTTP_200_OK,
    summary="Provide Loan Guidance (Officer)",
    description="Allow an Agricultural Officer to provide guidance notes and update status.",
)
def update_loan_enquiry_guidance(
    enquiry_id: int,
    payload: LoanEnquiryGuidanceUpdate,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> LoanEnquiryResponse:
    enquiry = officer_review_loan_enquiry(db, enquiry_id, current_officer, payload)
    return LoanEnquiryResponse.model_validate(enquiry)
