"""Business logic for assistance request photo and document attachments."""

import os
import uuid
from pathlib import Path
from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AuthorizationError, NotFoundError
from app.models.assistance_request import AssistanceRequest
from app.models.request_attachment import RequestAttachment
from app.models.user import User

ATTACHMENTS_DIR = Path("uploads/attachments")
ATTACHMENTS_DIR.mkdir(parents=True, exist_ok=True)
ALLOWED_MIME_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "application/pdf": ".pdf",
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def save_request_attachment(
    db: Session,
    request_id: int,
    current_user: User,
    file: UploadFile,
    description: str | None = None,
) -> RequestAttachment:
    """Upload and record a supporting photo or report for an assistance request."""
    request = db.get(AssistanceRequest, request_id)
    if not request:
        raise NotFoundError("Assistance request not found.")

    # Ownership check: Only owning farmer or assigned officer can attach files
    if current_user.id != request.farmer_id and current_user.id != request.officer_id:
        raise AuthorizationError("You do not have permission to attach files to this request.")

    content_type = file.content_type or ""
    if content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Allowed formats: JPG, PNG, WEBP, PDF.",
        )

    # Read bytes and validate size
    contents = file.file.read()
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File size exceeds maximum allowed limit of 10 MB.",
        )

    ext = ALLOWED_MIME_TYPES[content_type]
    unique_name = f"req_{request_id}_{uuid.uuid4().hex[:12]}{ext}"
    saved_path = ATTACHMENTS_DIR / unique_name

    with open(saved_path, "wb") as f:
        f.write(contents)

    attachment = RequestAttachment(
        request_id=request_id,
        uploader_id=current_user.id,
        file_name=file.filename or unique_name,
        file_path=str(saved_path).replace("\\", "/"),
        file_type=content_type,
        file_size_bytes=len(contents),
        description=description,
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)
    return attachment


def list_request_attachments(
    db: Session,
    request_id: int,
    current_user: User,
) -> list[RequestAttachment]:
    """List all attachments for an assistance request."""
    request = db.get(AssistanceRequest, request_id)
    if not request:
        raise NotFoundError("Assistance request not found.")

    if current_user.id != request.farmer_id and current_user.id != request.officer_id:
        raise AuthorizationError("You do not have permission to view attachments for this request.")

    stmt = select(RequestAttachment).where(RequestAttachment.request_id == request_id).order_by(RequestAttachment.id.asc())
    return list(db.scalars(stmt).all())
