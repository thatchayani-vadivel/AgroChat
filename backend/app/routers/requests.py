"""REST endpoints for Agricultural Assistance Requests and Consultations."""

from typing import Literal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.constants import ConsultationStatus, RequestStatus
from app.core.dependencies import (
    get_current_farmer,
    get_current_officer,
    get_current_user,
)
from app.db.session import get_db
from app.models.user import User
from app.schemas.request import (
    AssistanceRequestCreate,
    AssistanceRequestResponse,
    ConsultationResponse,
    RequestAcceptPayload,
    RequestRejectPayload,
    RequestStatusUpdatePayload,
)
from app.services.request_service import (
    accept_request,
    cancel_farmer_request,
    create_assistance_request,
    get_consultation_details,
    get_request_details,
    list_consultations,
    list_farmer_requests,
    list_officer_requests,
    reject_request,
    update_request_status,
)

requests_router = APIRouter(prefix="/api/requests", tags=["Assistance Requests"])
consultations_router = APIRouter(prefix="/api/consultations", tags=["Consultations"])


@requests_router.post(
    "",
    response_model=AssistanceRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit Assistance Request (Farmer)",
    description="Create a new agricultural assistance request optionally linked to a farm, crop, or preferred officer.",
)
def submit_request(
    payload: AssistanceRequestCreate,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> AssistanceRequestResponse:
    return create_assistance_request(db, current_farmer, payload)


@requests_router.get(
    "/my",
    response_model=list[AssistanceRequestResponse],
    status_code=status.HTTP_200_OK,
    summary="Track My Requests (Farmer)",
    description="List assistance requests submitted by the authenticated Farmer.",
)
def read_my_requests(
    request_status: RequestStatus | None = Query(default=None, alias="status"),
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> list[AssistanceRequestResponse]:
    return list_farmer_requests(db, current_farmer, status_filter=request_status)


@requests_router.get(
    "/officer",
    response_model=list[AssistanceRequestResponse],
    status_code=status.HTTP_200_OK,
    summary="View Officer Requests (Officer)",
    description="List open pending requests and requests assigned to the authenticated Agricultural Officer.",
)
def read_officer_requests(
    scope: Literal["all", "assigned", "open"] = Query(default="all"),
    request_status: RequestStatus | None = Query(default=None, alias="status"),
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> list[AssistanceRequestResponse]:
    return list_officer_requests(
        db=db,
        officer_user=current_officer,
        scope=scope,
        status_filter=request_status,
    )


@requests_router.get(
    "/{request_id}",
    response_model=AssistanceRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Assistance Request Details",
    description="Get details for an assistance request (owning Farmer or assigned/eligible Officer).",
)
def read_request_detail(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AssistanceRequestResponse:
    return get_request_details(db, request_id, current_user)


@requests_router.patch(
    "/{request_id}/cancel",
    response_model=AssistanceRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Cancel Pending Request (Farmer)",
    description="Allow a Farmer to cancel their own pending assistance request.",
)
def cancel_my_request(
    request_id: int,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> AssistanceRequestResponse:
    return cancel_farmer_request(db, request_id, current_farmer)


@requests_router.post(
    "/{request_id}/accept",
    response_model=AssistanceRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Accept Request (Officer)",
    description="Accept a pending farmer request and automatically open an active consultation.",
)
def accept_farmer_request(
    request_id: int,
    payload: RequestAcceptPayload | None = None,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> AssistanceRequestResponse:
    return accept_request(
        db=db,
        request_id=request_id,
        officer_user=current_officer,
        payload=payload or RequestAcceptPayload(),
    )


@requests_router.post(
    "/{request_id}/reject",
    response_model=AssistanceRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Reject Request (Officer)",
    description="Reject a pending farmer request with an explanation.",
)
def reject_farmer_request(
    request_id: int,
    payload: RequestRejectPayload,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> AssistanceRequestResponse:
    return reject_request(db, request_id, current_officer, payload)


@requests_router.patch(
    "/{request_id}/status",
    response_model=AssistanceRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Request Status & Guidance (Officer)",
    description="Update an accepted request to in_progress or resolved and record officer guidance.",
)
def patch_request_status(
    request_id: int,
    payload: RequestStatusUpdatePayload,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> AssistanceRequestResponse:
    return update_request_status(db, request_id, current_officer, payload)


@consultations_router.get(
    "",
    response_model=list[ConsultationResponse],
    status_code=status.HTTP_200_OK,
    summary="List My Consultations",
    description="Return active and completed consultation history for the authenticated Farmer or Officer.",
)
def read_my_consultations(
    consultation_status: ConsultationStatus | None = Query(default=None, alias="status"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ConsultationResponse]:
    return list_consultations(db, current_user, status_filter=consultation_status)


@consultations_router.get(
    "/{consultation_id}",
    response_model=ConsultationResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Consultation Details",
    description="Return consultation details and recommendations for an authorized participant.",
)
def read_consultation_detail(
    consultation_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ConsultationResponse:
    return get_consultation_details(db, consultation_id, current_user)

