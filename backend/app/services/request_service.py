"""Business logic for Agricultural Assistance Requests and Consultations."""

from datetime import datetime, timezone

from fastapi import status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload

from app.core.constants import (
    ConsultationStatus,
    NotificationType,
    RequestStatus,
    UserRole,
)
from app.core.exceptions import AgroChatException, AuthorizationError, NotFoundError
from app.models.assistance_request import AssistanceRequest
from app.models.consultation import Consultation
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.user import User
from app.schemas.request import (
    AssistanceRequestCreate,
    AssistanceRequestResponse,
    ConsultationResponse,
    RequestAcceptPayload,
    RequestRejectPayload,
    RequestStatusUpdatePayload,
)
from app.services.notification_service import create_notification


def _load_request(db: Session, request_id: int) -> AssistanceRequest:
    """Load an AssistanceRequest with related entities or raise 404."""
    req = db.scalar(
        select(AssistanceRequest)
        .options(
            joinedload(AssistanceRequest.farmer),
            joinedload(AssistanceRequest.officer),
            joinedload(AssistanceRequest.farm),
            joinedload(AssistanceRequest.crop),
            joinedload(AssistanceRequest.consultation),
        )
        .where(AssistanceRequest.id == request_id)
    )
    if req is None:
        raise NotFoundError("Assistance request not found.")
    return req


def _to_request_response(req: AssistanceRequest) -> AssistanceRequestResponse:
    """Serialize AssistanceRequest with linked names for UI display."""
    return AssistanceRequestResponse(
        id=req.id,
        farmer_id=req.farmer_id,
        officer_id=req.officer_id,
        farm_id=req.farm_id,
        crop_id=req.crop_id,
        title=req.title,
        category=req.category,
        description=req.description,
        priority=req.priority,
        status=req.status,
        officer_notes=req.officer_notes,
        rejection_reason=req.rejection_reason,
        accepted_at=req.accepted_at,
        resolved_at=req.resolved_at,
        created_at=req.created_at,
        updated_at=req.updated_at,
        farmer_name=req.farmer.full_name if req.farmer else None,
        farmer_phone=req.farmer.phone_number if req.farmer else None,
        officer_name=req.officer.full_name if req.officer else None,
        farm_name=req.farm.farm_name if req.farm else None,
        crop_name=req.crop.crop_name if req.crop else None,
        consultation_id=req.consultation.id if req.consultation else None,
    )


def _to_consultation_response(consultation: Consultation) -> ConsultationResponse:
    """Serialize Consultation with linked request, farmer, officer, farm, and crop info."""
    req = consultation.request
    return ConsultationResponse(
        id=consultation.id,
        request_id=consultation.request_id,
        farmer_id=consultation.farmer_id,
        officer_id=consultation.officer_id,
        status=consultation.status,
        guidance_summary=consultation.guidance_summary,
        recommendations=consultation.recommendations,
        started_at=consultation.started_at,
        completed_at=consultation.completed_at,
        updated_at=consultation.updated_at,
        request_title=req.title if req else None,
        request_category=req.category if req else None,
        request_status=req.status if req else None,
        farmer_name=consultation.farmer.full_name if consultation.farmer else None,
        officer_name=consultation.officer.full_name if consultation.officer else None,
        farm_name=req.farm.farm_name if req and req.farm else None,
        crop_name=req.crop.crop_name if req and req.crop else None,
    )


def _ensure_request_view_access(req: AssistanceRequest, current_user: User) -> None:
    """Verify the current user is allowed to view the assistance request."""
    if current_user.role == UserRole.FARMER:
        if req.farmer_id != current_user.id:
            raise AuthorizationError("You do not have permission to view this request.")
        return

    # Agricultural Officer can view assigned requests or unassigned pending requests
    if req.officer_id == current_user.id:
        return
    if req.officer_id is None and req.status == RequestStatus.PENDING:
        return
    raise AuthorizationError("This request is assigned to another Agricultural Officer.")


def _ensure_officer_can_act_on_pending(req: AssistanceRequest, officer_user: User) -> None:
    """Verify an Officer can accept or reject a pending request."""
    if req.status != RequestStatus.PENDING:
        raise AgroChatException(
            detail=f"Cannot perform this action because request status is '{req.status.value}'.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Invalid Request State",
        )
    if req.officer_id is not None and req.officer_id != officer_user.id:
        raise AuthorizationError("This request is specifically assigned to another Officer.")


def create_assistance_request(
    db: Session, farmer_user: User, payload: AssistanceRequestCreate
) -> AssistanceRequestResponse:
    """Create a new agricultural assistance request for a Farmer."""
    resolved_farm_id = payload.farm_id

    if payload.farm_id is not None:
        farm = db.scalar(
            select(Farm)
            .options(joinedload(Farm.farmer_profile))
            .where(Farm.id == payload.farm_id)
        )
        if farm is None:
            raise NotFoundError("Selected farm was not found.")
        if farm.farmer_profile.user_id != farmer_user.id:
            raise AuthorizationError("You can only link your own farms to a request.")

    if payload.crop_id is not None:
        crop = db.scalar(
            select(Crop)
            .options(joinedload(Crop.farm).joinedload(Farm.farmer_profile))
            .where(Crop.id == payload.crop_id)
        )
        if crop is None:
            raise NotFoundError("Selected crop was not found.")
        if crop.farm.farmer_profile.user_id != farmer_user.id:
            raise AuthorizationError("You can only link your own crops to a request.")
        if resolved_farm_id is not None and crop.farm_id != resolved_farm_id:
            raise AgroChatException(
                detail="Selected crop does not belong to the selected farm.",
                status_code=status.HTTP_400_BAD_REQUEST,
                error="Invalid Crop Selection",
            )
        resolved_farm_id = crop.farm_id

    preferred_officer: User | None = None
    if payload.preferred_officer_id is not None:
        preferred_officer = db.get(User, payload.preferred_officer_id)
        if (
            preferred_officer is None
            or not preferred_officer.is_active
            or preferred_officer.role != UserRole.AGRICULTURAL_OFFICER
        ):
            raise NotFoundError("Selected Agricultural Officer was not found or is inactive.")

    new_req = AssistanceRequest(
        farmer_id=farmer_user.id,
        officer_id=preferred_officer.id if preferred_officer else None,
        farm_id=resolved_farm_id,
        crop_id=payload.crop_id,
        title=payload.title,
        category=payload.category,
        description=payload.description,
        priority=payload.priority,
        status=RequestStatus.PENDING,
    )
    db.add(new_req)
    db.flush()

    if preferred_officer is not None:
        create_notification(
            db=db,
            user_id=preferred_officer.id,
            title="New Assistance Request Assigned",
            message=f"{farmer_user.full_name} submitted a request: {new_req.title}",
            notification_type=NotificationType.REQUEST_CREATED,
            related_request_id=new_req.id,
        )

    db.commit()
    return _to_request_response(_load_request(db, new_req.id))


def list_farmer_requests(
    db: Session,
    farmer_user: User,
    status_filter: RequestStatus | None = None,
) -> list[AssistanceRequestResponse]:
    """List assistance requests submitted by the authenticated Farmer."""
    stmt = (
        select(AssistanceRequest)
        .options(
            joinedload(AssistanceRequest.farmer),
            joinedload(AssistanceRequest.officer),
            joinedload(AssistanceRequest.farm),
            joinedload(AssistanceRequest.crop),
            joinedload(AssistanceRequest.consultation),
        )
        .where(AssistanceRequest.farmer_id == farmer_user.id)
    )
    if status_filter is not None:
        stmt = stmt.where(AssistanceRequest.status == status_filter)
    stmt = stmt.order_by(AssistanceRequest.created_at.desc(), AssistanceRequest.id.desc())
    return [_to_request_response(r) for r in db.scalars(stmt).all()]


def list_officer_requests(
    db: Session,
    officer_user: User,
    scope: str = "all",
    status_filter: RequestStatus | None = None,
) -> list[AssistanceRequestResponse]:
    """List assistance requests visible to the authenticated Agricultural Officer."""
    stmt = select(AssistanceRequest).options(
        joinedload(AssistanceRequest.farmer),
        joinedload(AssistanceRequest.officer),
        joinedload(AssistanceRequest.farm),
        joinedload(AssistanceRequest.crop),
        joinedload(AssistanceRequest.consultation),
    )

    if scope == "assigned":
        stmt = stmt.where(AssistanceRequest.officer_id == officer_user.id)
    elif scope == "open":
        stmt = stmt.where(
            AssistanceRequest.officer_id.is_(None),
            AssistanceRequest.status == RequestStatus.PENDING,
        )
    else:
        stmt = stmt.where(
            or_(
                AssistanceRequest.officer_id == officer_user.id,
                (AssistanceRequest.officer_id.is_(None))
                & (AssistanceRequest.status == RequestStatus.PENDING),
            )
        )

    if status_filter is not None:
        stmt = stmt.where(AssistanceRequest.status == status_filter)

    stmt = stmt.order_by(AssistanceRequest.created_at.desc(), AssistanceRequest.id.desc())
    return [_to_request_response(r) for r in db.scalars(stmt).all()]


def get_request_details(
    db: Session, request_id: int, current_user: User
) -> AssistanceRequestResponse:
    """Return details of an assistance request if the user is authorized to view it."""
    req = _load_request(db, request_id)
    _ensure_request_view_access(req, current_user)
    return _to_request_response(req)


def cancel_farmer_request(
    db: Session, request_id: int, farmer_user: User
) -> AssistanceRequestResponse:
    """Allow a Farmer to cancel their own pending assistance request."""
    req = _load_request(db, request_id)
    if req.farmer_id != farmer_user.id:
        raise AuthorizationError("You do not have permission to cancel this request.")
    if req.status != RequestStatus.PENDING:
        raise AgroChatException(
            detail="Only pending requests can be cancelled.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Invalid Request State",
        )

    req.status = RequestStatus.CANCELLED
    db.commit()
    return _to_request_response(_load_request(db, req.id))


def accept_request(
    db: Session,
    request_id: int,
    officer_user: User,
    payload: RequestAcceptPayload,
) -> AssistanceRequestResponse:
    """Allow an Agricultural Officer to accept a pending request and start a consultation."""
    req = _load_request(db, request_id)
    _ensure_officer_can_act_on_pending(req, officer_user)

    now = datetime.now(timezone.utc)
    req.officer_id = officer_user.id
    req.status = RequestStatus.ACCEPTED
    req.accepted_at = now
    if payload.officer_notes is not None:
        req.officer_notes = payload.officer_notes

    consultation = Consultation(
        request_id=req.id,
        farmer_id=req.farmer_id,
        officer_id=officer_user.id,
        status=ConsultationStatus.ACTIVE,
        guidance_summary=payload.officer_notes,
    )
    db.add(consultation)

    create_notification(
        db=db,
        user_id=req.farmer_id,
        title="Assistance Request Accepted",
        message=f"Officer {officer_user.full_name} accepted your request '{req.title}'. You can now chat.",
        notification_type=NotificationType.REQUEST_ACCEPTED,
        related_request_id=req.id,
    )

    db.commit()
    return _to_request_response(_load_request(db, req.id))


def reject_request(
    db: Session,
    request_id: int,
    officer_user: User,
    payload: RequestRejectPayload,
) -> AssistanceRequestResponse:
    """Allow an Agricultural Officer to reject a pending request with a reason."""
    req = _load_request(db, request_id)
    _ensure_officer_can_act_on_pending(req, officer_user)

    req.officer_id = officer_user.id
    req.status = RequestStatus.REJECTED
    req.rejection_reason = payload.rejection_reason

    create_notification(
        db=db,
        user_id=req.farmer_id,
        title="Assistance Request Declined",
        message=f"Officer {officer_user.full_name} declined '{req.title}': {payload.rejection_reason}",
        notification_type=NotificationType.REQUEST_REJECTED,
        related_request_id=req.id,
    )

    db.commit()
    return _to_request_response(_load_request(db, req.id))


def update_request_status(
    db: Session,
    request_id: int,
    officer_user: User,
    payload: RequestStatusUpdatePayload,
) -> AssistanceRequestResponse:
    """Allow the assigned Agricultural Officer to update status and guidance."""
    req = _load_request(db, request_id)
    if req.officer_id != officer_user.id:
        raise AuthorizationError("Only the assigned Agricultural Officer can update this request.")

    if req.status not in (RequestStatus.ACCEPTED, RequestStatus.IN_PROGRESS):
        raise AgroChatException(
            detail=f"Cannot update status when request is '{req.status.value}'.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Invalid Request State",
        )

    now = datetime.now(timezone.utc)
    req.status = payload.status
    if payload.officer_notes is not None:
        req.officer_notes = payload.officer_notes
    if payload.status == RequestStatus.RESOLVED:
        req.resolved_at = now

    consultation = req.consultation
    if consultation is None:
        consultation = Consultation(
            request_id=req.id,
            farmer_id=req.farmer_id,
            officer_id=officer_user.id,
            status=ConsultationStatus.ACTIVE,
        )
        db.add(consultation)

    if payload.guidance_summary is not None:
        consultation.guidance_summary = payload.guidance_summary
    if payload.recommendations is not None:
        consultation.recommendations = payload.recommendations
    if payload.status == RequestStatus.RESOLVED:
        consultation.status = ConsultationStatus.COMPLETED
        consultation.completed_at = now

    status_label = payload.status.value.replace("_", " ").title()
    create_notification(
        db=db,
        user_id=req.farmer_id,
        title=f"Request Status Updated: {status_label}",
        message=f"Officer {officer_user.full_name} updated '{req.title}' to {status_label}.",
        notification_type=NotificationType.REQUEST_UPDATED,
        related_request_id=req.id,
    )

    db.commit()
    return _to_request_response(_load_request(db, req.id))


def list_consultations(
    db: Session,
    current_user: User,
    status_filter: ConsultationStatus | None = None,
) -> list[ConsultationResponse]:
    """List active or past consultations for the authenticated Farmer or Officer."""
    stmt = select(Consultation).options(
        joinedload(Consultation.farmer),
        joinedload(Consultation.officer),
        joinedload(Consultation.request).joinedload(AssistanceRequest.farm),
        joinedload(Consultation.request).joinedload(AssistanceRequest.crop),
    )
    if current_user.role == UserRole.FARMER:
        stmt = stmt.where(Consultation.farmer_id == current_user.id)
    else:
        stmt = stmt.where(Consultation.officer_id == current_user.id)

    if status_filter is not None:
        stmt = stmt.where(Consultation.status == status_filter)

    stmt = stmt.order_by(Consultation.updated_at.desc(), Consultation.id.desc())
    return [_to_consultation_response(c) for c in db.scalars(stmt).all()]


def get_consultation_details(
    db: Session, consultation_id: int, current_user: User
) -> ConsultationResponse:
    """Return a specific consultation if the current user is a participant."""
    consultation = db.scalar(
        select(Consultation)
        .options(
            joinedload(Consultation.farmer),
            joinedload(Consultation.officer),
            joinedload(Consultation.request).joinedload(AssistanceRequest.farm),
            joinedload(Consultation.request).joinedload(AssistanceRequest.crop),
        )
        .where(Consultation.id == consultation_id)
    )
    if consultation is None:
        raise NotFoundError("Consultation not found.")
    if current_user.id not in (consultation.farmer_id, consultation.officer_id):
        raise AuthorizationError("You do not have permission to view this consultation.")
    return _to_consultation_response(consultation)

