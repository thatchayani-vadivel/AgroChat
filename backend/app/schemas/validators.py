"""Shared Pydantic field validation helpers."""

import re

PHONE_PATTERN = re.compile(r"^[+\d\s\-()]{7,20}$")
PINCODE_PATTERN = re.compile(r"^[A-Za-z0-9\s\-]{4,12}$")


def clean_required_text(value: str, min_length: int = 2) -> str:
    """Trim whitespace and ensure a required string meets minimum length."""
    cleaned = value.strip()
    if len(cleaned) < min_length:
        raise ValueError(f"Value must contain at least {min_length} non-whitespace characters.")
    return cleaned


def clean_optional_text(value: str | None) -> str | None:
    """Trim optional string and convert empty strings to None."""
    if value is None:
        return None
    cleaned = value.strip()
    return cleaned if cleaned else None


def validate_phone_format(value: str) -> str:
    """Validate and normalize a phone number string."""
    cleaned = value.strip()
    if not PHONE_PATTERN.match(cleaned):
        raise ValueError("Invalid phone number format.")
    digits = [ch for ch in cleaned if ch.isdigit()]
    if len(digits) < 7 or len(digits) > 15:
        raise ValueError("Phone number must contain between 7 and 15 digits.")
    return cleaned


def validate_optional_pincode(value: str | None) -> str | None:
    """Validate optional postal/pin code."""
    cleaned = clean_optional_text(value)
    if cleaned is None:
        return None
    if not PINCODE_PATTERN.match(cleaned):
        raise ValueError("Invalid pincode format.")
    return cleaned

