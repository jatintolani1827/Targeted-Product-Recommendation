from __future__ import annotations

from datetime import datetime, timedelta
from uuid import uuid4

from psycopg2.extras import RealDictCursor

from backend.app import app
from ml.etl_pipeline import run_etl
from ml.full_pipeline import run_full_pipeline
from ml.ml_complementary import run_complementary_pipeline
from ml.ml_pipeline import train_and_store_similarities


def insert_product(
    conn,
    *,
    category_id: int,
    price: int,
    stock: int = 25,
    name_prefix: str,
) -> int:
    unique_name = f"{name_prefix} {uuid4().hex[:8]}"
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO products (name, price, category_id, brand, stock, attributes)
            VALUES (%s, %s, %s, %s, %s, %s::jsonb)
            RETURNING product_id
            """,
            (unique_name, price, category_id, "Complement Brand", stock, '{"ml_test": true}'),
        )
        product_id = cur.fetchone()["product_id"]
    conn.commit()
    return product_id


def insert_order(conn, *, user_id: int, items: list[tuple[int, int]], days_ago: int) -> int:
    order_time = datetime.now() - timedelta(days=days_ago)

    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        pricing_rows = {}
        for product_id, _quantity in items:
            cur.execute(
                "SELECT price, category_id FROM products WHERE product_id = %s",
                (product_id,),
            )
            pricing_rows[product_id] = cur.fetchone()

        total_amount = sum(pricing_rows[product_id]["price"] * quantity for product_id, quantity in items)

        cur.execute(
            """
            INSERT INTO orders (user_id, total_amt, created_at)
            VALUES (%s, %s, %s)
            RETURNING order_id
            """,
            (user_id, total_amount, order_time),
        )
        order_id = cur.fetchone()["order_id"]

        for product_id, quantity in items:
            product = pricing_rows[product_id]
            cur.execute(
                """
                INSERT INTO order_details (order_id, product_id, quantity, unit_price, category_id)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (order_id, product_id, quantity, product["price"], product["category_id"]),
            )

    conn.commit()
    return order_id


def test_complementary_pipeline_generates_directional_accessory_pairs(admin_conn):
    unique_suffix = uuid4().hex[:8]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO users (email, full_name)
            VALUES (%s, %s), (%s, %s)
            RETURNING user_id, email
            """,
            (
                f"complement-a-{unique_suffix}@example.com",
                f"Complement A {unique_suffix}",
                f"complement-b-{unique_suffix}@example.com",
                f"Complement B {unique_suffix}",
            ),
        )
        users = {row["email"]: row["user_id"] for row in cur.fetchall()}
    admin_conn.commit()

    keyboard_id = insert_product(admin_conn, category_id=5, price=9000, name_prefix="ML Keyboard")
    wrist_rest_id = insert_product(admin_conn, category_id=12, price=1800, name_prefix="ML Wrist Rest")
    mouse_id = insert_product(admin_conn, category_id=10, price=3500, name_prefix="ML Mouse")

    user_a = users[f"complement-a-{unique_suffix}@example.com"]
    user_b = users[f"complement-b-{unique_suffix}@example.com"]

    for offset in range(1, 7):
        insert_order(admin_conn, user_id=user_a, items=[(keyboard_id, 1), (wrist_rest_id, 1)], days_ago=offset)

    for offset in range(7, 11):
        insert_order(admin_conn, user_id=user_a, items=[(keyboard_id, 1)], days_ago=offset)

    for offset in range(1, 9):
        insert_order(admin_conn, user_id=user_b, items=[(mouse_id, 1)], days_ago=offset)

    run_etl(hours_back=24 * 365 * 5)
    train_and_store_similarities()
    result = run_complementary_pipeline(min_support=0.05, min_lift=1.10)

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT pair_type, lift_score, confidence, composite_score
            FROM complementary_pairs
            WHERE product_id = %s
              AND complement_id = %s
            """,
            (keyboard_id, wrist_rest_id),
        )
        pair = cur.fetchone()

        cur.execute(
            """
            SELECT COUNT(*) AS invalid_pairs
            FROM complementary_pairs cp
            JOIN products p1 ON p1.product_id = cp.product_id
            JOIN products p2 ON p2.product_id = cp.complement_id
            WHERE p1.category_id = p2.category_id
            """
        )
        invalid_pairs = cur.fetchone()["invalid_pairs"]

        cur.execute(
            """
            SELECT similarity_score
            FROM product_similarity
            WHERE product_id_1 = %s
              AND product_id_2 = %s
              AND source = 'complementary'
            """,
            (keyboard_id, wrist_rest_id),
        )
        mirrored_similarity = cur.fetchone()

    assert result["pairs_upserted"] >= 1
    assert pair is not None
    assert pair["pair_type"] == "accessory"
    assert float(pair["lift_score"]) > 1.0
    assert float(pair["composite_score"]) > 0.4
    assert invalid_pairs == 0
    assert mirrored_similarity is not None


def test_full_pipeline_refreshes_seeded_demo_recommendations(admin_conn):
    result = run_full_pipeline(hours_back=24 * 365 * 5)

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT r.match_score
            FROM recommendations r
            JOIN users u ON u.user_id = r.user_id
            JOIN products p ON p.product_id = r.product_id
            WHERE u.email = 'vivaan@example.com'
              AND p.name = 'Razer Gigantus V2 Medium'
              AND r.seen_flag = FALSE
            """
        )
        recommendation = cur.fetchone()

    assert result["users_refreshed"] >= 8
    assert recommendation is not None
    assert float(recommendation["match_score"]) > 0


def test_refresh_all_endpoint_returns_user_count():
    with app.test_client() as client:
        response = client.post("/api/recommendations/refresh-all")

    assert response.status_code == 200
    assert response.get_json()["refreshed_users"] >= 8


def test_recommendations_endpoint_surfaces_complementary_labels(admin_conn):
    unique_suffix = uuid4().hex[:8]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO users (email, full_name)
            VALUES (%s, %s), (%s, %s)
            RETURNING user_id, email
            """,
            (
                f"rec-seed-{unique_suffix}@example.com",
                f"Rec Seed {unique_suffix}",
                f"rec-target-{unique_suffix}@example.com",
                f"Rec Target {unique_suffix}",
            ),
        )
        users = {row["email"]: row["user_id"] for row in cur.fetchall()}
    admin_conn.commit()

    keyboard_id = insert_product(admin_conn, category_id=5, price=8500, name_prefix="API Keyboard")
    wrist_rest_id = insert_product(admin_conn, category_id=12, price=1500, name_prefix="API Wrist Rest")
    mouse_id = insert_product(admin_conn, category_id=10, price=2800, name_prefix="API Mouse")

    seed_user = users[f"rec-seed-{unique_suffix}@example.com"]
    target_user = users[f"rec-target-{unique_suffix}@example.com"]

    for offset in range(1, 6):
        insert_order(admin_conn, user_id=seed_user, items=[(keyboard_id, 1), (wrist_rest_id, 1)], days_ago=offset)

    for offset in range(6, 9):
        insert_order(admin_conn, user_id=seed_user, items=[(keyboard_id, 1)], days_ago=offset)

    for offset in range(1, 6):
        insert_order(admin_conn, user_id=seed_user, items=[(mouse_id, 1)], days_ago=offset)

    insert_order(admin_conn, user_id=target_user, items=[(keyboard_id, 1)], days_ago=1)

    run_etl(hours_back=24 * 365 * 5)
    train_and_store_similarities()
    run_complementary_pipeline(min_support=0.05, min_lift=1.05)

    with admin_conn.cursor() as cur:
        cur.execute("CALL sp_refresh_user_recommendations(%s, %s)", (target_user, keyboard_id))
    admin_conn.commit()

    with app.test_client() as client:
        response = client.get(f"/api/recommendations?user_id={target_user}")

    assert response.status_code == 200
    payload = response.get_json()
    wrist_rest_rec = next((row for row in payload if row["product_id"] == wrist_rest_id), None)

    assert wrist_rest_rec is not None
    assert wrist_rest_rec["rec_type"] == "complementary"
    assert wrist_rest_rec["pair_type"] == "accessory"
    assert wrist_rest_rec["display_label"] == "Complete Your Setup"
