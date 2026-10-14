from __future__ import annotations

from datetime import datetime, timedelta
from uuid import uuid4

from psycopg2.extras import RealDictCursor

from backend.purchase_handler import process_purchase
from ml.etl_pipeline import run_etl


def insert_product(conn, *, category_id: int, stock: int = 5, name_prefix: str = "Test Product") -> int:
    unique_name = f"{name_prefix} {uuid4().hex[:8]}"
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO products (name, price, category_id, brand, stock, attributes)
            VALUES (%s, %s, %s, %s, %s, %s::jsonb)
            RETURNING product_id
            """,
            (unique_name, 19999, category_id, "Test Brand", stock, '{"wireless": true}'),
        )
        product_id = cur.fetchone()["product_id"]
    conn.commit()
    return product_id


def insert_order(conn, *, user_id: int, product_id: int, days_ago: int) -> None:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT price, category_id FROM products WHERE product_id = %s", (product_id,))
        product = cur.fetchone()
        order_time = datetime.now() - timedelta(days=days_ago)

        cur.execute(
            """
            INSERT INTO orders (user_id, total_amt, created_at)
            VALUES (%s, %s, %s)
            RETURNING order_id
            """,
            (user_id, product["price"], order_time),
        )
        order_id = cur.fetchone()["order_id"]
        cur.execute(
            """
            INSERT INTO order_details (order_id, product_id, quantity, unit_price, category_id)
            VALUES (%s, %s, 1, %s, %s)
            """,
            (order_id, product_id, product["price"], product["category_id"]),
        )
    conn.commit()


def test_insert_product_creates_queue_row(admin_conn):
    product_id = insert_product(admin_conn, category_id=3, name_prefix="Queue Trigger Product")

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            "SELECT status FROM recommendation_queue WHERE product_id = %s ORDER BY queue_id DESC LIMIT 1",
            (product_id,),
        )
        queue_row = cur.fetchone()

    assert queue_row is not None
    assert queue_row["status"] == "pending"


def test_generated_recommendations_target_only_top_value_users(admin_conn):
    product_id = insert_product(admin_conn, category_id=5, name_prefix="Keyboard Launch")

    with admin_conn.cursor() as cur:
        cur.execute("UPDATE recommendation_queue SET status = 'processing' WHERE product_id = %s", (product_id,))
        cur.execute("CALL sp_generate_recommendations(%s)", (product_id,))
    admin_conn.commit()

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT r.user_id, m.rfm_tier
            FROM recommendations r
            JOIN mv_user_rfm_scores m ON m.user_id = r.user_id
            WHERE r.product_id = %s
            """,
            (product_id,),
        )
        rows = cur.fetchall()

    assert rows, "Expected recommendations to be generated for seeded data"
    assert {row["rfm_tier"] for row in rows}.issubset({"champions", "loyal"})


def test_cooldown_exclusion_logic(admin_conn):
    unique_suffix = uuid4().hex[:8]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO users (email, full_name)
            VALUES (%s, %s), (%s, %s)
            RETURNING user_id, email
            """,
            (
                f"eligible-{unique_suffix}@example.com",
                f"Eligible {unique_suffix}",
                f"cooldown-{unique_suffix}@example.com",
                f"Cooldown {unique_suffix}",
            ),
        )
        inserted_users = cur.fetchall()
    admin_conn.commit()

    user_map = {row["email"]: row["user_id"] for row in inserted_users}
    eligible_user_id = user_map[f"eligible-{unique_suffix}@example.com"]
    cooldown_user_id = user_map[f"cooldown-{unique_suffix}@example.com"]

    headphone_product_ids = [1, 2, 8]
    smart_home_product_id = 7

    for offset, product_id in zip([95, 80, 65, 50, 35], headphone_product_ids * 2):
        insert_order(admin_conn, user_id=eligible_user_id, product_id=product_id, days_ago=offset)

    insert_order(admin_conn, user_id=eligible_user_id, product_id=smart_home_product_id, days_ago=10)

    for offset, product_id in zip([120, 90, 60, 45, 32], headphone_product_ids * 2):
        insert_order(admin_conn, user_id=cooldown_user_id, product_id=product_id, days_ago=offset)

    insert_order(admin_conn, user_id=cooldown_user_id, product_id=1, days_ago=5)

    with admin_conn.cursor() as cur:
        cur.execute("SELECT fn_refresh_rfm_scores()")
    admin_conn.commit()

    product_id = insert_product(admin_conn, category_id=3, name_prefix="Cooldown Launch")

    with admin_conn.cursor() as cur:
        cur.execute("UPDATE recommendation_queue SET status = 'processing' WHERE product_id = %s", (product_id,))
        cur.execute("CALL sp_generate_recommendations(%s)", (product_id,))
    admin_conn.commit()

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            "SELECT user_id FROM recommendations WHERE product_id = %s",
            (product_id,),
        )
        targeted_users = {row["user_id"] for row in cur.fetchall()}

        cur.execute(
            """
            SELECT user_id, rfm_tier
            FROM mv_user_rfm_scores
            WHERE user_id IN (%s, %s)
            """,
            (eligible_user_id, cooldown_user_id),
        )
        tiers = {row["user_id"]: row["rfm_tier"] for row in cur.fetchall()}

    assert tiers[eligible_user_id] in {"champions", "loyal"}
    assert tiers[cooldown_user_id] in {"champions", "loyal"}
    assert eligible_user_id in targeted_users
    assert cooldown_user_id not in targeted_users


def test_purchase_refreshes_active_recommendations(admin_conn):
    user_id = 1

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("CALL sp_refresh_user_recommendations(%s, %s)", (user_id, 1))
        cur.execute(
            """
            SELECT product_id
            FROM recommendations
            WHERE user_id = %s
              AND seen_flag = FALSE
            ORDER BY match_score DESC, product_id
            LIMIT 1
            """,
            (user_id,),
        )
        active_recommendation = cur.fetchone()
    admin_conn.commit()

    assert active_recommendation is not None
    purchased_product_id = active_recommendation["product_id"]

    result = process_purchase(user_id=user_id, product_id=purchased_product_id, quantity=1)
    assert result["success"] is True

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT seen_flag, clicked_flag
            FROM recommendations
            WHERE user_id = %s
              AND product_id = %s
            """,
            (user_id, purchased_product_id),
        )
        purchased_recommendation = cur.fetchone()

        cur.execute(
            """
            SELECT product_id
            FROM recommendations
            WHERE user_id = %s
              AND seen_flag = FALSE
            ORDER BY generated_at DESC, match_score DESC
            """,
            (user_id,),
        )
        refreshed_recommendations = {row["product_id"] for row in cur.fetchall()}

    assert purchased_recommendation is not None
    assert purchased_recommendation["seen_flag"] is True
    assert purchased_recommendation["clicked_flag"] is True
    assert purchased_product_id not in refreshed_recommendations
    assert refreshed_recommendations


def test_keyboard_purchase_can_generate_wrist_rest_recommendations(admin_conn):
    unique_suffix = uuid4().hex[:8]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO users (email, full_name)
            VALUES (%s, %s)
            RETURNING user_id
            """,
            (f"taxonomy-{unique_suffix}@example.com", f"Taxonomy {unique_suffix}"),
        )
        user_id = cur.fetchone()["user_id"]
    admin_conn.commit()

    keyboard_product_id = insert_product(admin_conn, category_id=5, name_prefix="Keyboard")
    wrist_rest_product_id = insert_product(admin_conn, category_id=12, name_prefix="Wrist Rest")
    insert_order(admin_conn, user_id=user_id, product_id=keyboard_product_id, days_ago=1)

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("CALL sp_refresh_user_recommendations(%s, %s)", (user_id, keyboard_product_id))
        cur.execute(
            """
            SELECT match_score
            FROM recommendations
            WHERE user_id = %s
              AND product_id = %s
              AND seen_flag = FALSE
            """,
            (user_id, wrist_rest_product_id),
        )
        recommendation = cur.fetchone()
    admin_conn.commit()

    assert recommendation is not None
    assert recommendation["match_score"] > 0


def test_etl_syncs_catalog_products_without_orders(admin_conn):
    product_id = insert_product(admin_conn, category_id=12, name_prefix="Catalog Only Wrist Rest")

    result = run_etl(hours_back=1)

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT product_id FROM dw.dim_product WHERE product_id = %s", (product_id,))
        dim_product = cur.fetchone()

    assert result["products_synced"] >= 1
    assert dim_product is not None
