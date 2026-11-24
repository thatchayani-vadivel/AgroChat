"""Pydantic schemas for Farmer–Officer chat and voice messages."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.constants import MessageType, UserRole
from app.schemas.validators import clean_required_text


class TextMessageCreate(BaseModel):
    """Payload for sending a text chat message."""

    content: str = Field(..., min_length=1, max_length=3000)

    @field_validator("content")
    @classmethod
    def validate_content(cls, value: str) -> str:
        return clean_required_text(value, min_length=1)


class MessageResponse(BaseModel):
    """Response schema for a chat text or voice message."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    request_id: int
    sender_id: int
    receiver_id: int
    sender_name: str | None = None
    sender_role: UserRole | None = None
    message_type: MessageType
    content: str | None
    audio_file_name: str | None
    audio_url: str | None
    duration_seconds: int | None
    is_read: bool
    created_at: datetime

