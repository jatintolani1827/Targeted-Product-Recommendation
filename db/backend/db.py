from __future__ import annotations

from contextlib import contextmanager
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Iterator

from psycopg2 import pool
from psycopg2.extras import Json, RealDictCursor

from backend.config import settings


_POOLS: dict[str, pool.SimpleConnectionPool] = {}


def get_pool(dsn: str) -> pool.SimpleConnectionPool:
    if dsn not in _POOLS:
        _POOLS[dsn] = pool.SimpleConnectionPool(1, 10, dsn=dsn)
    return _POOLS[dsn]


@contextmanager
def get_connection(*, admin: bool = False) -> Iterator[Any]:
    dsn = settings.admin_database_url if admin else settings.database_url
    conn = get_pool(dsn).getconn()
    try:
        conn.autocommit = False
        yield conn
    finally:
        try:
            conn.rollback()
        except Exception:
            pass
        conn.autocommit = False
        get_pool(dsn).putconn(conn)


def fetch_all(query: str, params: tuple[Any, ...] | None = None, *, admin: bool = False) -> list[dict[str, Any]]:
    with get_connection(admin=admin) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            rows = cur.fetchall()
    return [serialize(row) for row in rows]


def fetch_one(query: str, params: tuple[Any, ...] | None = None, *, admin: bool = False) -> dict[str, Any] | None:
    with get_connection(admin=admin) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            row = cur.fetchone()
    return serialize(row) if row else None


def execute(
    query: str,
    params: tuple[Any, ...] | None = None,
    *,
    admin: bool = False,
    fetchone: bool = False,
    fetchall: bool = False,
    commit: bool = True,
) -> Any:
    with get_connection(admin=admin) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            result = None
            if fetchone:
                result = cur.fetchone()
            elif fetchall:
                result = cur.fetchall()
            if commit:
                conn.commit()
            else:
                conn.rollback()
    return serialize(result)


def to_json(value: Any) -> Json:
    return Json(value)


def serialize(value: Any) -> Any:
    if isinstance(value, list):
        return [serialize(item) for item in value]
    if isinstance(value, dict):
        return {key: serialize(item) for key, item in value.items()}
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    return value
