"""MySQL database engine, session factory, and connectivity check."""

from collections.abc import Generator
import logging

from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings

logger = logging.getLogger("agrochat.db")

settings = get_settings()

# Build URL via URL.create so special characters in credentials are safely escaped.
DATABASE_URL = URL.create(
    drivername="mysql+pymysql",
    username=settings.DB_USER,
    password=settings.DB_PASSWORD,
    host=settings.DB_HOST,
    port=settings.DB_PORT,
    database=settings.DB_NAME,
    query={"charset": "utf8mb4"},
)

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
    connect_args={"connect_timeout": 5},
    echo=settings.DEBUG,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def get_db() -> Generator[Session, None, None]:
    """Yield a scoped database session and ensure it closes cleanly."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_db_connection() -> tuple[bool, str]:
    """Verify MySQL connectivity without exposing sensitive credentials."""
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
        return True, "MySQL connection verified successfully."
    except SQLAlchemyError as exc:
        logger.warning("Database health check failed: %s", type(exc).__name__)
        return (
            False,
            "Unable to connect to MySQL database. Verify DB settings in .env and ensure the database exists.",
        )

