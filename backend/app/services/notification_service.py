"""Business logic for user notifications."""

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.core.constants import NotificationType
from app.core.exceptions import AuthorizationError, NotFoundError
from app.models.notification import Notification
from app.schemas.notification import NotificationListResponse, NotificationResponse


def create_notification(
    db: Session,
    user_id: int,
    title: str,
    message: str,
    notification_type: NotificationType,
    related_request_id: int | None = None,
) -> Notification:
    """Create and stage a notification record within the active database transaction."""
    notification = Notification(
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type,
        related_request_id=related_request_id,
        is_read=False,
    )
    db.add(notification)
    return notification


def list_user_notifications(
    db: Session, user_id: int, unread_only: bool = False
) -> NotificationListResponse:
    """List notifications for the authenticated user with unread count."""
    unread_count = (
        db.scalar(
            select(func.count(Notification.id)).where(
                Notification.user_id == user_id,
                Notification.is_read.is_(False),
            )
        )
        or 0
    )

    stmt = select(Notification).where(Notification.user_id == user_id)
    if unread_only:
        stmt = stmt.where(Notification.is_read.is_(False))
    stmt = stmt.order_by(Notification.created_at.desc(), Notification.id.desc())

    items = db.scalars(stmt).all()
    return NotificationListResponse(
        unread_count=int(unread_count),
        items=[NotificationResponse.model_validate(item) for item in items],
    )


def mark_notification_read(
    db: Session, notification_id: int, user_id: int
) -> NotificationResponse:
    """Mark a single notification as read if owned by the current user."""
    notification = db.get(Notification, notification_id)
    if notification is None:
        raise NotFoundError("Notification not found.")
    if notification.user_id != user_id:
        raise AuthorizationError("You do not have permission to modify this notification.")

    if not notification.is_read:
        notification.is_read = True
        db.commit()
        db.refresh(notification)
    return NotificationResponse.model_validate(notification)


def mark_all_notifications_read(db: Session, user_id: int) -> int:
    """Mark all unread notifications for the current user as read."""
    result = db.execute(
        update(Notification)
        .where(Notification.user_id == user_id, Notification.is_read.is_(False))
        .values(is_read=True)
    )
    db.commit()
    return int(result.rowcount or 0)

