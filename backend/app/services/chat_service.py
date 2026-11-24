"""Business logic for Farmer–Officer chat and voice messaging."""

from pathlib import Path
import re
from uuid import uuid4

from fastapi import UploadFile, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session, joinedload

from app.core.config import get_settings
from app.core.constants import MessageType, NotificationType, RequestStatus
from app.core.exceptions import AgroChatException, AuthorizationError, NotFoundError
from app.models.assistance_request import AssistanceRequest
from app.models.message import Message
from app.models.user import User
from app.schemas.chat import MessageResponse, TextMessageCreate
from app.services.notification_service import create_notification

ALLOWED_AUDIO_EXTENSIONS = {".m4a", ".mp3", ".wav", ".ogg", ".webm", ".aac"}
SAFE_VOICE_FILENAME_PATTERN = re.compile(r"^[a-f0-9]{32}\.(m4a|mp3|wav|ogg|webm|aac)$")
AUDIO_MEDIA_TYPES = {
    ".m4a": "audio/mp4",
    ".mp3": "audio/mpeg",
    ".wav": "audio/wav",
    ".ogg": "audio/ogg",
    ".webm": "audio/webm",
    ".aac": "audio/aac",
}


def _to_message_response(msg: Message) -> MessageResponse:
    """Serialize a Message ORM object with sender metadata."""
    return MessageResponse(
        id=msg.id,
        request_id=msg.request_id,
        sender_id=msg.sender_id,
        receiver_id=msg.receiver_id,
        sender_name=msg.sender.full_name if msg.sender else None,
        sender_role=msg.sender.role if msg.sender else None,
        message_type=msg.message_type,
        content=msg.content,
        audio_file_name=msg.audio_file_name,
        audio_url=msg.audio_url,
        duration_seconds=msg.duration_seconds,
        is_read=msg.is_read,
        created_at=msg.created_at,
    )


def _get_chat_context(
    db: Session, request_id: int, current_user: User, require_writable: bool
) -> tuple[AssistanceRequest, int]:
    """Verify request chat eligibility, participant ownership, and compute receiver_id."""
    req = db.get(AssistanceRequest, request_id)
    if req is None:
        raise NotFoundError("Assistance request not found.")

    if req.officer_id is None or req.status in (
        RequestStatus.PENDING,
        RequestStatus.REJECTED,
        RequestStatus.CANCELLED,
    ):
        raise AgroChatException(
            detail="Chat is only available once an Agricultural Officer accepts the request.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Chat Unavailable",
        )

    if current_user.id not in (req.farmer_id, req.officer_id):
        raise AuthorizationError("You are not a participant in this consultation chat.")

    if require_writable and req.status == RequestStatus.RESOLVED:
        raise AgroChatException(
            detail="This assistance request is resolved. Chat is now read-only.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Chat Closed",
        )

    receiver_id = req.officer_id if current_user.id == req.farmer_id else req.farmer_id
    return req, receiver_id


def list_request_messages(
    db: Session, request_id: int, current_user: User
) -> list[MessageResponse]:
    """Return ordered chat messages for a request and mark incoming messages as read."""
    _get_chat_context(db, request_id, current_user, require_writable=False)

    db.execute(
        update(Message)
        .where(
            Message.request_id == request_id,
            Message.receiver_id == current_user.id,
            Message.is_read.is_(False),
        )
        .values(is_read=True)
    )
    db.commit()

    messages = db.scalars(
        select(Message)
        .options(joinedload(Message.sender))
        .where(Message.request_id == request_id)
        .order_by(Message.created_at.asc(), Message.id.asc())
    ).all()
    return [_to_message_response(m) for m in messages]


def send_text_message(
    db: Session,
    request_id: int,
    current_user: User,
    payload: TextMessageCreate,
) -> MessageResponse:
    """Send a text message inside an active Farmer–Officer consultation."""
    req, receiver_id = _get_chat_context(db, request_id, current_user, require_writable=True)

    msg = Message(
        request_id=req.id,
        sender_id=current_user.id,
        receiver_id=receiver_id,
        message_type=MessageType.TEXT,
        content=payload.content,
        is_read=False,
    )
    db.add(msg)

    create_notification(
        db=db,
        user_id=receiver_id,
        title=f"New Message from {current_user.full_name}",
        message=payload.content[:140],
        notification_type=NotificationType.NEW_MESSAGE,
        related_request_id=req.id,
    )

    db.commit()
    loaded = db.scalar(
        select(Message).options(joinedload(Message.sender)).where(Message.id == msg.id)
    )
    return _to_message_response(loaded or msg)


async def send_voice_message(
    db: Session,
    request_id: int,
    current_user: User,
    audio_file: UploadFile,
    duration_seconds: int | None = None,
    caption: str | None = None,
) -> MessageResponse:
    """Validate, store, and record a voice message inside an active consultation."""
    req, receiver_id = _get_chat_context(db, request_id, current_user, require_writable=True)

    original_name = audio_file.filename or ""
    ext = Path(original_name).suffix.lower()
    if ext not in ALLOWED_AUDIO_EXTENSIONS:
        raise AgroChatException(
            detail=(
                "Unsupported audio format. Allowed formats: "
                + ", ".join(sorted(ALLOWED_AUDIO_EXTENSIONS))
            ),
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            error="Unsupported Media Type",
        )

    if duration_seconds is not None and duration_seconds < 0:
        raise AgroChatException(
            detail="duration_seconds must be zero or positive.",
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            error="Validation Error",
        )

    settings = get_settings()
    max_bytes = settings.MAX_VOICE_FILE_SIZE_MB * 1024 * 1024
    content_bytes = await audio_file.read()
    if not content_bytes:
        raise AgroChatException(
            detail="Uploaded voice file is empty.",
            status_code=status.HTTP_400_BAD_REQUEST,
            error="Empty File",
        )
    if len(content_bytes) > max_bytes:
        raise AgroChatException(
            detail=f"Voice file exceeds maximum allowed size of {settings.MAX_VOICE_FILE_SIZE_MB} MB.",
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            error="Payload Too Large",
        )

    upload_dir = settings.voice_upload_dir
    upload_dir.mkdir(parents=True, exist_ok=True)
    stored_filename = f"{uuid4().hex}{ext}"
    destination = upload_dir / stored_filename
    destination.write_bytes(content_bytes)

    cleaned_caption = caption.strip() if caption and caption.strip() else None

    msg = Message(
        request_id=req.id,
        sender_id=current_user.id,
        receiver_id=receiver_id,
        message_type=MessageType.VOICE,
        content=cleaned_caption,
        audio_file_name=stored_filename,
        audio_url=f"/api/chat/voice/{stored_filename}",
        duration_seconds=duration_seconds,
        is_read=False,
    )
    db.add(msg)

    create_notification(
        db=db,
        user_id=receiver_id,
        title=f"New Voice Message from {current_user.full_name}",
        message=cleaned_caption or "Sent a voice message.",
        notification_type=NotificationType.NEW_MESSAGE,
        related_request_id=req.id,
    )

    db.commit()
    loaded = db.scalar(
        select(Message).options(joinedload(Message.sender)).where(Message.id == msg.id)
    )
    return _to_message_response(loaded or msg)


def resolve_voice_file(filename: str) -> tuple[Path, str]:
    """Safely validate and resolve a stored voice file path and media type."""
    if not SAFE_VOICE_FILENAME_PATTERN.match(filename):
        raise NotFoundError("Voice message file not found.")

    upload_dir = get_settings().voice_upload_dir.resolve()
    target = (upload_dir / filename).resolve()
    if target.parent != upload_dir or not target.is_file():
        raise NotFoundError("Voice message file not found.")

    media_type = AUDIO_MEDIA_TYPES.get(target.suffix.lower(), "application/octet-stream")
    return target, media_type

