from __future__ import annotations

import time
from typing import Any

from psycopg2.extras import RealDictCursor

from backend.config import settings
from backend.db import get_connection


CLAIM_SQL = """
WITH next_job AS (
    SELECT queue_id, product_id
    FROM recommendation_queue
    WHERE status = 'pending'
    ORDER BY created_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED
)
UPDATE recommendation_queue q
SET status = 'processing',
    error_msg = NULL
FROM next_job
WHERE q.queue_id = next_job.queue_id
RETURNING q.queue_id, q.product_id;
"""


def process_once() -> dict[str, Any] | None:
    with get_connection(admin=False) as conn:
        conn.autocommit = False
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(CLAIM_SQL)
                job = cur.fetchone()
                if not job:
                    conn.commit()
                    return None

                cur.execute("CALL sp_generate_recommendations(%s)", (job["product_id"],))
            conn.commit()
            return {"queue_id": job["queue_id"], "product_id": job["product_id"]}
        except Exception:
            conn.rollback()
            raise


def run_forever(poll_seconds: int | None = None) -> None:
    interval = poll_seconds or settings.queue_poll_seconds
    while True:
        processed = process_once()
        if not processed:
            time.sleep(interval)


if __name__ == "__main__":
    run_forever()

