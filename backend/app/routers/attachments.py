"""REST endpoints for Assistance Request Attachments (crop disease photos, reports)."""

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.request_attachment import RequestAttachmentResponse
from app.services.attachment_service import (
    list_request_attachments,
    save_request_attachment,
)

router = APIRouter(prefix="/api/requests", tags=["Request Attachments"])


@router.post(
    "/{request_id}/attachments",
    response_model=RequestAttachmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload Request Attachment",
    description="Upload a photo (JPG, PNG, WEBP) or document (PDF) for an assistance request.",
)
def upload_attachment(
    request_id: int,
    file: UploadFile = File(...),
    description: str | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> RequestAttachmentResponse:
    attachment = save_request_attachment(
        db=db,
        request_id=request_id,
        current_user=current_user,
        file=file,
        description=description,
    )
    return RequestAttachmentResponse.model_validate(attachment)


@router.get(
    "/{request_id}/attachments",
    response_model=list[RequestAttachmentResponse],
    status_code=status.HTTP_200_OK,
    summary="List Request Attachments",
    description="List all photo and document attachments for an assistance request.",
)
def read_attachments(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[RequestAttachmentResponse]:
    attachments = list_request_attachments(db, request_id, current_user)
    return [RequestAttachmentResponse.model_validate(a) for a in attachments]
