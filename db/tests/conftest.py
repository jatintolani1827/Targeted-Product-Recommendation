from __future__ import annotations

import sys
from pathlib import Path

import psycopg2
import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from backend.config import settings  # noqa: E402
from backend.queue_worker import process_once  # noqa: E402
from ml.full_pipeline import run_full_pipeline  # noqa: E402
from scripts.bootstrap_db import main as bootstrap_main  # noqa: E402


def _ensure_database() -> None:
    try:
        with psycopg2.connect(settings.admin_database_url):
            return
    except Exception as exc:
        pytest.skip(f"Database is unavailable for integration tests: {exc}")


@pytest.fixture(scope="session", autouse=True)
def bootstrap_database():
    _ensure_database()
    bootstrap_main()
    run_full_pipeline(hours_back=24 * 365 * 5)
    process_once()


@pytest.fixture()
def admin_conn():
    conn = psycopg2.connect(settings.admin_database_url)
    yield conn
    conn.close()


@pytest.fixture()
def customer_conn():
    conn = psycopg2.connect("postgresql://customer_user:secure_pass@localhost:5433/recommendation_engine")
    yield conn
    conn.close()


@pytest.fixture()
def analyst_conn():
    conn = psycopg2.connect("postgresql://analyst_user:secure_pass@localhost:5433/recommendation_engine")
    yield conn
    conn.close()
