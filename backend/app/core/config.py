"""Application configuration loaded from environment variables."""

from functools import lru_cache
from pathlib import Path

from pydantic import Field, ValidationError, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]
ENV_FILE_PATH = BACKEND_DIR / ".env"


class Settings(BaseSettings):
    """Application settings validated from .env and environment variables."""

    APP_NAME: str = "AgroChat API"
    APP_VERSION: str = "1.0.0"
    APP_ENV: str = "development"
    DEBUG: bool = False

    API_HOST: str = "127.0.0.1"
    API_PORT: int = 8000
    CORS_ORIGINS: str = "*"

    # Database configuration (must be provided via .env or environment)
    DB_HOST: str = Field(..., min_length=1)
    DB_PORT: int = Field(default=3306, ge=1, le=65535)
    DB_USER: str = Field(..., min_length=1)
    DB_PASSWORD: str = Field(...)
    DB_NAME: str = Field(..., min_length=1)

    # Security and JWT settings (SECRET_KEY must be provided via .env or environment)
    SECRET_KEY: str = Field(..., min_length=8)
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=1440, ge=5, le=43200)

    # File upload settings
    MAX_VOICE_FILE_SIZE_MB: int = Field(default=10, ge=1, le=50)

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE_PATH),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, value: str) -> str:
        """Ensure SECRET_KEY is not blank whitespace."""
        if not value.strip():
            raise ValueError("SECRET_KEY must not be empty.")
        return value

    @property
    def voice_upload_dir(self) -> Path:
        """Return directory path for uploaded voice message audio files."""
        return BACKEND_DIR / "uploads" / "voice_messages"

    @property
    def cors_origins_list(self) -> list[str]:
        """Return parsed list of allowed CORS origins."""
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    """Load and cache application settings with clear configuration errors."""
    try:
        return Settings()
    except ValidationError as exc:
        missing_or_invalid = [
            ".".join(str(part) for part in err.get("loc", []))
            for err in exc.errors()
        ]
        raise RuntimeError(
            "Invalid or missing environment configuration in backend/.env. "
            f"Check fields: {', '.join(missing_or_invalid)}"
        ) from exc

