"""Pydantic schemas for user notifications."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.core.constants import NotificationType


class NotificationResponse(BaseModel):
    """Response schema for a single notification."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    title: str
    message: str
    notification_type: NotificationType
    related_request_id: int | None
    is_read: bool
    created_at: datetime


class NotificationListResponse(BaseModel):
    """Response schema wrapping notification items and unread count."""

    unread_count: int
    items: list[NotificationResponse]

