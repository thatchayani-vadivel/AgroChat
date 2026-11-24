"""Pydantic schemas for Request Attachments (crop photos, lab reports)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class RequestAttachmentResponse(BaseModel):
    """Response schema for an assistance request attachment."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    request_id: int
    uploader_id: int
    file_name: str
    file_path: str
    file_type: str
    file_size_bytes: int
    description: str | None = None
    created_at: datetime
