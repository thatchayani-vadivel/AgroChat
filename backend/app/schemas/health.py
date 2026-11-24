"""Response schemas for system root and health endpoints."""

from pydantic import BaseModel


class RootResponse(BaseModel):
    """Response payload for GET /."""

    app: str
    version: str
    status: str
    message: str
    roles: list[str]
    docs_url: str
    redoc_url: str


class HealthResponse(BaseModel):
    """Response payload for GET /health."""

    status: str
    service: str
    version: str
    database: str
    detail: str

