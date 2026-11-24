"""Custom exceptions and global FastAPI error handlers."""

import logging

from fastapi import FastAPI, Request, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("agrochat.exceptions")


class AgroChatException(Exception):
    """Base application exception for predictable API errors."""

    def __init__(
        self,
        detail: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        error: str = "Application Error",
    ) -> None:
        self.detail = detail
        self.status_code = status_code
        self.error = error
        super().__init__(detail)


class DatabaseConnectionError(AgroChatException):
    """Raised when the database cannot be reached."""

    def __init__(self, detail: str = "Database service is currently unavailable.") -> None:
        super().__init__(
            detail=detail,
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            error="Database Unavailable",
        )


class DuplicateResourceError(AgroChatException):
    """Raised when attempting to create a duplicate unique resource."""

    def __init__(self, detail: str = "Resource already exists.") -> None:
        super().__init__(
            detail=detail,
            status_code=status.HTTP_409_CONFLICT,
            error="Conflict",
        )


class AuthenticationError(AgroChatException):
    """Raised when credentials or authentication tokens are missing or invalid."""

    def __init__(self, detail: str = "Could not validate credentials.") -> None:
        super().__init__(
            detail=detail,
            status_code=status.HTTP_401_UNAUTHORIZED,
            error="Unauthorized",
        )


class AuthorizationError(AgroChatException):
    """Raised when an authenticated user lacks permission for a resource."""

    def __init__(
        self, detail: str = "You do not have permission to access this resource."
    ) -> None:
        super().__init__(
            detail=detail,
            status_code=status.HTTP_403_FORBIDDEN,
            error="Forbidden",
        )


class NotFoundError(AgroChatException):
    """Raised when a requested resource cannot be found."""

    def __init__(self, detail: str = "Resource not found.") -> None:
        super().__init__(
            detail=detail,
            status_code=status.HTTP_404_NOT_FOUND,
            error="Not Found",
        )


def _error_payload(error: str, detail: object, status_code: int) -> dict[str, object]:
    """Build a consistent JSON error payload."""
    return {
        "success": False,
        "status_code": status_code,
        "error": error,
        "detail": detail,
    }


def register_exception_handlers(app: FastAPI) -> None:
    """Attach centralized exception handlers to the FastAPI instance."""

    @app.exception_handler(AgroChatException)
    async def agrochat_exception_handler(
        request: Request, exc: AgroChatException
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_payload(exc.error, exc.detail, exc.status_code),
        )

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(
        request: Request, exc: StarletteHTTPException
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_payload("HTTP Error", exc.detail, exc.status_code),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content=_error_payload(
                "Validation Error",
                jsonable_encoder(exc.errors()),
                status.HTTP_422_UNPROCESSABLE_CONTENT,
            ),
        )

    @app.exception_handler(SQLAlchemyError)
    async def sqlalchemy_exception_handler(
        request: Request, exc: SQLAlchemyError
    ) -> JSONResponse:
        logger.exception("Unhandled SQLAlchemy error on %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=_error_payload(
                "Database Error",
                "A database error occurred while processing your request.",
                status.HTTP_500_INTERNAL_SERVER_ERROR,
            ),
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        logger.exception("Unhandled server error on %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=_error_payload(
                "Internal Server Error",
                "An unexpected internal server error occurred.",
                status.HTTP_500_INTERNAL_SERVER_ERROR,
            ),
        )

