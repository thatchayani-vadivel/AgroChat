"""REST endpoints for user notifications."""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.farm import MessageResponse
from app.schemas.notification import NotificationListResponse, NotificationResponse
from app.services.notification_service import (
    list_user_notifications,
    mark_all_notifications_read,
    mark_notification_read,
)

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])


@router.get(
    "",
    response_model=NotificationListResponse,
    status_code=status.HTTP_200_OK,
    summary="List My Notifications",
    description="Return notifications and unread count for the authenticated Farmer or Officer.",
)
def read_my_notifications(
    unread_only: bool = Query(default=False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> NotificationListResponse:
    return list_user_notifications(db, current_user.id, unread_only=unread_only)


@router.patch(
    "/read-all",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark All Notifications Read",
    description="Mark all unread notifications as read for the authenticated user.",
)
def read_all_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    updated = mark_all_notifications_read(db, current_user.id)
    return MessageResponse(message=f"Marked {updated} notification(s) as read.")


@router.patch(
    "/{notification_id}/read",
    response_model=NotificationResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark Notification Read",
    description="Mark a single notification owned by the authenticated user as read.",
)
def read_single_notification(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> NotificationResponse:
    return mark_notification_read(db, notification_id, current_user.id)

