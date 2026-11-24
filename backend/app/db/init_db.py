"""Database initialization helpers for creating MySQL tables."""

import logging

from sqlalchemy.exc import SQLAlchemyError

import app.models  # noqa: F401 - ensure all ORM models are registered with Base.metadata
from app.db.base import Base
from app.db.seed_data import seed_reference_data
from app.db.session import SessionLocal, engine

logger = logging.getLogger("agrochat.db.init")


def create_tables() -> bool:
    """Create all registered ORM tables in MySQL if they do not exist and seed reference data."""
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables verified/created successfully.")
        with SessionLocal() as db:
            seed_reference_data(db)
        return True
    except SQLAlchemyError as exc:
        logger.warning("Could not verify/create database tables: %s", type(exc).__name__)
        return False

