from __future__ import annotations

import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    database_url: str = os.getenv(
        "DATABASE_URL",
        "postgresql://app_user:secure_pass@localhost:5433/recommendation_engine",
    )
    admin_database_url: str = os.getenv(
        "ADMIN_DATABASE_URL",
        "postgresql://postgres:postgres@localhost:5433/recommendation_engine",
    )
    api_host: str = os.getenv("API_HOST", "0.0.0.0")
    api_port: int = int(os.getenv("API_PORT", "5000"))
    frontend_origin: str = os.getenv("FRONTEND_ORIGIN", "http://localhost:5173")
    queue_poll_seconds: int = int(os.getenv("QUEUE_POLL_SECONDS", "5"))


settings = Settings()
