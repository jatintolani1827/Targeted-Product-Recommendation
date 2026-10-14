from __future__ import annotations

import sys
import threading
from pathlib import Path

import psycopg2
from psycopg2.extras import RealDictCursor

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from backend.config import settings  # noqa: E402
from backend.purchase_handler import process_purchase  # noqa: E402


def create_flash_sale_product() -> int:
    with psycopg2.connect(settings.admin_database_url) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO products (name, price, category_id, brand, stock, attributes)
                VALUES ('Flash Sale Demo Product', 9999, 3, 'Demo Brand', 1, '{"demo": true}'::jsonb)
                ON CONFLICT DO NOTHING
                """
            )
            cur.execute(
                "SELECT product_id FROM products WHERE name = 'Flash Sale Demo Product' ORDER BY product_id DESC LIMIT 1"
            )
            product_id = cur.fetchone()["product_id"]
        conn.commit()
    return product_id


def get_stock(product_id: int) -> int:
    with psycopg2.connect(settings.admin_database_url) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT stock FROM products WHERE product_id = %s", (product_id,))
            return cur.fetchone()[0]


def main() -> None:
    product_id = create_flash_sale_product()
    results: list[dict[str, object]] = []
    lock = threading.Lock()

    def try_buy() -> None:
        result = process_purchase(user_id=1, product_id=product_id, quantity=1)
        with lock:
            results.append(result)

    threads = [threading.Thread(target=try_buy) for _ in range(50)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    successes = [result for result in results if result.get("success")]
    failures = [result for result in results if not result.get("success")]

    print(f"Successful purchases: {len(successes)}")
    print(f"Rolled back safely:   {len(failures)}")
    print(f"Final stock:          {get_stock(product_id)}")


if __name__ == "__main__":
    main()

