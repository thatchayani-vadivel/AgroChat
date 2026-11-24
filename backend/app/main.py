"""AgroChat FastAPI application entry point."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
import logging
from pathlib import Path
import sys

# Ensure backend root is always present in python path
_backend_root = str(Path(__file__).resolve().parent.parent)
if _backend_root not in sys.path:
    sys.path.insert(0, _backend_root)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.exceptions import register_exception_handlers
from app.db.init_db import create_tables
from app.db.session import check_db_connection, engine
from app.routers.advisory import router as advisory_router
from app.routers.attachments import router as attachments_router
from app.routers.auth import router as auth_router
from app.routers.chat import router as chat_router
from app.routers.farmer_profile import router as farmer_profile_router
from app.routers.farms import router as farms_router
from app.routers.health import router as health_router
from app.routers.loans import router as loans_router
from app.routers.marketplace import router as marketplace_router
from app.routers.notifications import router as notifications_router
from app.routers.officer_profile import router as officer_profile_router
from app.routers.rental_bookings import router as rental_bookings_router
from app.routers.requests import consultations_router, requests_router
from app.routers.subsidies import router as subsidies_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("agrochat.main")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Manage startup diagnostics and clean shutdown of database resources."""
    settings = get_settings()
    logger.info("Starting %s v%s (%s)", settings.APP_NAME, settings.APP_VERSION, settings.APP_ENV)

    is_connected, detail = check_db_connection()
    if is_connected:
        logger.info("Startup DB check: %s", detail)
        create_tables()
    else:
        logger.warning("Startup DB check: %s", detail)

    yield

    engine.dispose()
    logger.info("Database connection pool disposed. Shutdown complete.")


def create_app() -> FastAPI:
    """Create and configure the AgroChat FastAPI application."""
    settings = get_settings()

    application = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=(
            "Digital Agriculture Advisory and Farmer–Officer Communication Platform API. "
            "Supports two user roles: Farmer and Agricultural Officer."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # Allow Flutter Web / Chrome and mobile clients to communicate with the API.
    origins = settings.cors_origins_list
    application.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=(origins != ["*"]),
        allow_methods=["*"],
        allow_headers=["*"],
        allow_private_network=True,
    )

    register_exception_handlers(application)
    application.include_router(health_router)
    application.include_router(auth_router)
    application.include_router(farmer_profile_router)
    application.include_router(officer_profile_router)
    application.include_router(farms_router)
    application.include_router(requests_router)
    application.include_router(attachments_router)
    application.include_router(consultations_router)
    application.include_router(chat_router)
    application.include_router(notifications_router)
    application.include_router(advisory_router)
    application.include_router(loans_router)
    application.include_router(subsidies_router)
    application.include_router(marketplace_router)
    application.include_router(rental_bookings_router)

    return application


app = create_app()

