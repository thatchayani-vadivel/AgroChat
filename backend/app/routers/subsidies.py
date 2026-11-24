"""REST endpoints for Government Subsidy Enquiries and Officer Guidance."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer, get_current_officer, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.subsidy import (
    SubsidyEnquiryCreate,
    SubsidyEnquiryGuidanceUpdate,
    SubsidyEnquiryResponse,
)
from app.services.loan_subsidy_service import (
    create_subsidy_enquiry,
    get_subsidy_enquiry_details,
    list_all_subsidy_enquiries_for_officers,
    list_farmer_subsidy_enquiries,
    officer_review_subsidy_enquiry,
)

router = APIRouter(prefix="/api/subsidies", tags=["Government Schemes & Subsidies"])


@router.post(
    "/enquiries",
    response_model=SubsidyEnquiryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit Subsidy Enquiry (Farmer)",
    description="Submit an enquiry for agricultural subsidy application assistance.",
)
def submit_subsidy_enquiry(
    payload: SubsidyEnquiryCreate,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> SubsidyEnquiryResponse:
    enquiry = create_subsidy_enquiry(db, current_farmer, payload)
    return SubsidyEnquiryResponse.model_validate(enquiry)


@router.get(
    "/enquiries/my",
    response_model=list[SubsidyEnquiryResponse],
    status_code=status.HTTP_200_OK,
    summary="Track My Subsidy Enquiries (Farmer)",
    description="List all subsidy enquiries submitted by the authenticated Farmer.",
)
def read_my_subsidy_enquiries(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> list[SubsidyEnquiryResponse]:
    enquiries = list_farmer_subsidy_enquiries(db, current_farmer)
    return [SubsidyEnquiryResponse.model_validate(e) for e in enquiries]


@router.get(
    "/enquiries",
    response_model=list[SubsidyEnquiryResponse],
    status_code=status.HTTP_200_OK,
    summary="List All Subsidy Enquiries (Officer)",
    description="Allow Agricultural Officers to view subsidy enquiries across farmers.",
)
def read_all_subsidy_enquiries(
    _current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> list[SubsidyEnquiryResponse]:
    enquiries = list_all_subsidy_enquiries_for_officers(db)
    return [SubsidyEnquiryResponse.model_validate(e) for e in enquiries]


@router.get(
    "/enquiries/{enquiry_id}",
    response_model=SubsidyEnquiryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Subsidy Enquiry Details",
    description="View details of a subsidy enquiry (owning Farmer or Agricultural Officer).",
)
def read_subsidy_enquiry_detail(
    enquiry_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> SubsidyEnquiryResponse:
    enquiry = get_subsidy_enquiry_details(db, enquiry_id, current_user)
    return SubsidyEnquiryResponse.model_validate(enquiry)


@router.patch(
    "/enquiries/{enquiry_id}/guidance",
    response_model=SubsidyEnquiryResponse,
    status_code=status.HTTP_200_OK,
    summary="Provide Subsidy Guidance (Officer)",
    description="Allow an Agricultural Officer to provide guidance notes on a subsidy enquiry.",
)
def update_subsidy_enquiry_guidance(
    enquiry_id: int,
    payload: SubsidyEnquiryGuidanceUpdate,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> SubsidyEnquiryResponse:
    enquiry = officer_review_subsidy_enquiry(db, enquiry_id, current_officer, payload)
    return SubsidyEnquiryResponse.model_validate(enquiry)
