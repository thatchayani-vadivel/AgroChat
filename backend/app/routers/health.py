"""System root and health check endpoints."""

from fastapi import APIRouter, status
from fastapi.responses import JSONResponse

from app.core.config import get_settings
from app.core.constants import UserRole
from app.db.session import check_db_connection
from app.schemas.health import HealthResponse, RootResponse

router = APIRouter(tags=["System & Health"])


@router.get(
    "/",
    response_model=RootResponse,
    summary="API Root",
    description="Returns basic AgroChat API metadata and supported user roles.",
)
def read_root() -> RootResponse:
    """Return service status and API entry metadata."""
    settings = get_settings()
    return RootResponse(
        app=settings.APP_NAME,
        version=settings.APP_VERSION,
        status="running",
        message="Welcome to the AgroChat Digital Agriculture Advisory API.",
        roles=[role.value for role in UserRole],
        docs_url="/docs",
        redoc_url="/redoc",
    )


@router.get(
    "/health",
    response_model=HealthResponse,
    responses={
        status.HTTP_503_SERVICE_UNAVAILABLE: {
            "model": HealthResponse,
            "description": "API is running, but MySQL database connection failed.",
        }
    },
    summary="Health Check",
    description="Checks API availability and MySQL database connectivity.",
)
@router.get(
    "/api/health",
    response_model=HealthResponse,
    include_in_schema=False,
)
def health_check() -> JSONResponse:
    """Verify API and database health."""
    settings = get_settings()
    is_connected, detail = check_db_connection()

    payload = HealthResponse(
        status="healthy" if is_connected else "degraded",
        service=settings.APP_NAME,
        version=settings.APP_VERSION,
        database="connected" if is_connected else "disconnected",
        detail=detail,
    )
    response_code = (
        status.HTTP_200_OK if is_connected else status.HTTP_503_SERVICE_UNAVAILABLE
    )
    return JSONResponse(status_code=response_code, content=payload.model_dump())

