from __future__ import annotations

import time
from pathlib import Path

import psycopg2

from backend.config import settings


SQL_FILES = [
    "01_schema.sql",
    "02_dw_schema.sql",
    "03_views.sql",
    "04_materialized.sql",
    "05_triggers.sql",
    "06_procedures.sql",
    "07_indexes.sql",
    "08_rbac.sql",
    "09_seed_data.sql",
    "11_category_complements.sql",
]


def wait_for_database(retries: int = 30, delay_seconds: int = 2) -> None:
    last_error: Exception | None = None
    for _ in range(retries):
        try:
            with psycopg2.connect(settings.admin_database_url):
                return
        except Exception as exc:  # pragma: no cover - environment bootstrap
            last_error = exc
            time.sleep(delay_seconds)
    raise RuntimeError(f"Database did not become ready: {last_error}")


def apply_sql_file(conn, path: Path) -> None:
    sql = path.read_text()
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()


def reset_database(conn) -> None:
    with conn.cursor() as cur:
        cur.execute("DROP SCHEMA IF EXISTS dw CASCADE;")
        cur.execute("DROP SCHEMA IF EXISTS public CASCADE;")
        cur.execute("CREATE SCHEMA public;")
        cur.execute("GRANT ALL ON SCHEMA public TO postgres;")
        cur.execute("GRANT ALL ON SCHEMA public TO public;")
    conn.commit()


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    sql_dir = root / "database"
    wait_for_database()
    with psycopg2.connect(settings.admin_database_url) as conn:
        reset_database(conn)
        for filename in SQL_FILES:
            apply_sql_file(conn, sql_dir / filename)
            print(f"Applied {filename}")


if __name__ == "__main__":
    main()
