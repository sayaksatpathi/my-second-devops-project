"""Configuration via environment variables (12-factor). No secrets hardcoded."""
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="", extra="ignore")

    service_name: str = "user-api"
    port: int = 8000
    log_level: str = "INFO"

    # Postgres. Falls back to in-memory if unset (so the app runs with zero deps).
    database_url: str | None = None  # e.g. postgresql+psycopg2://user:pass@host:5432/db

    # Redis cache (optional; app degrades gracefully if down).
    redis_url: str | None = None  # e.g. redis://host:6379/0
    cache_ttl_seconds: int = 30

    # OpenTelemetry (optional; only enabled when an endpoint is set).
    otel_exporter_otlp_endpoint: str | None = None


@lru_cache
def get_settings() -> Settings:
    return Settings()
