"""Domain constants and enums for AgroChat.

AgroChat strictly supports two user roles: Farmer and Agricultural Officer.
"""

from enum import Enum


class UserRole(str, Enum):
    """Allowed user roles in the AgroChat platform."""

    FARMER = "farmer"
    AGRICULTURAL_OFFICER = "agricultural_officer"


class RequestStatus(str, Enum):
    """Lifecycle states of an agricultural assistance request."""

    PENDING = "pending"
    ACCEPTED = "accepted"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class RequestPriority(str, Enum):
    """Urgency levels for assistance requests."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class ConsultationStatus(str, Enum):
    """Lifecycle states of an active/completed consultation."""

    ACTIVE = "active"
    COMPLETED = "completed"


class MessageType(str, Enum):
    """Supported message content types in Farmer-Officer chat."""

    TEXT = "text"
    VOICE = "voice"


class NotificationType(str, Enum):
    """Categories of user notifications."""

    REQUEST_CREATED = "request_created"
    REQUEST_ACCEPTED = "request_accepted"
    REQUEST_REJECTED = "request_rejected"
    REQUEST_UPDATED = "request_updated"
    NEW_MESSAGE = "new_message"


class SchemeCategory(str, Enum):
    """Categories for government schemes, subsidies, loans, and insurance."""

    SCHEME = "scheme"
    SUBSIDY = "subsidy"
    LOAN = "loan"
    INSURANCE = "insurance"


class EquipmentAvailability(str, Enum):
    """Availability status of rental equipment."""

    AVAILABLE = "available"
    BOOKED = "booked"
    MAINTENANCE = "maintenance"
