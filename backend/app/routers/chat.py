"""REST endpoints for Farmer–Officer text and voice chat."""

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.chat import MessageResponse, TextMessageCreate
from app.services.chat_service import (
    list_request_messages,
    resolve_voice_file,
    send_text_message,
    send_voice_message,
)

router = APIRouter(prefix="/api/chat", tags=["Farmer–Officer Chat & Voice"])


@router.get(
    "/requests/{request_id}/messages",
    response_model=list[MessageResponse],
    status_code=status.HTTP_200_OK,
    summary="List Consultation Messages",
    description="Fetch text and voice messages for an accepted/active/resolved request and mark incoming messages read.",
)
def read_messages(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MessageResponse]:
    return list_request_messages(db, request_id, current_user)


@router.post(
    "/requests/{request_id}/messages",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Send Text Message",
    description="Send a text message between the Farmer and assigned Agricultural Officer.",
)
def post_text_message(
    request_id: int,
    payload: TextMessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    return send_text_message(db, request_id, current_user, payload)


@router.post(
    "/requests/{request_id}/voice",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Send Voice Message",
    description="Upload an audio file (.m4a, .mp3, .wav, .ogg, .webm, .aac) as a voice message.",
)
async def post_voice_message(
    request_id: int,
    audio_file: UploadFile = File(...),
    duration_seconds: int | None = Form(default=None),
    caption: str | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    return await send_voice_message(
        db=db,
        request_id=request_id,
        current_user=current_user,
        audio_file=audio_file,
        duration_seconds=duration_seconds,
        caption=caption,
    )


@router.get(
    "/voice/{filename}",
    status_code=status.HTTP_200_OK,
    summary="Stream Voice Message Audio",
    description="Serve a stored voice message audio file by its generated filename.",
)
def download_voice_message(filename: str) -> FileResponse:
    file_path, media_type = resolve_voice_file(filename)
    return FileResponse(path=file_path, media_type=media_type, filename=filename)

