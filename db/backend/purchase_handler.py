from __future__ import annotations

from typing import Any

from psycopg2.extras import RealDictCursor

from backend.db import get_connection, serialize


def process_purchase(user_id: int, product_id: int, quantity: int = 1) -> dict[str, Any]:
    if quantity <= 0:
        return {"success": False, "error": "Quantity must be positive"}

    with get_connection(admin=False) as conn:
        conn.autocommit = False
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(
                    """
                    SELECT stock, price, category_id
                    FROM products
                    WHERE product_id = %s
                    FOR UPDATE
                    """,
                    (product_id,),
                )
                product = cur.fetchone()
                if not product:
                    conn.rollback()
                    return {"success": False, "error": "Product not found"}

                cur.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
                if not cur.fetchone():
                    conn.rollback()
                    return {"success": False, "error": "User not found"}

                if product["stock"] < quantity:
                    conn.rollback()
                    return {"success": False, "error": "Insufficient stock"}

                cur.execute(
                    """
                    UPDATE products
                    SET stock = stock - %s
                    WHERE product_id = %s
                    RETURNING stock
                    """,
                    (quantity, product_id),
                )
                remaining_stock = cur.fetchone()["stock"]

                total_amount = product["price"] * quantity
                cur.execute(
                    """
                    INSERT INTO orders (user_id, total_amt)
                    VALUES (%s, %s)
                    RETURNING order_id, created_at
                    """,
                    (user_id, total_amount),
                )
                order = cur.fetchone()

                cur.execute(
                    """
                    INSERT INTO order_details (order_id, product_id, quantity, unit_price, category_id)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING detail_id
                    """,
                    (order["order_id"], product_id, quantity, product["price"], product["category_id"]),
                )
                detail = cur.fetchone()

                cur.execute(
                    """
                    UPDATE recommendations
                    SET clicked_flag = TRUE,
                        seen_flag = TRUE
                    WHERE user_id = %s AND product_id = %s
                    """,
                    (user_id, product_id),
                )

                cur.execute("CALL sp_refresh_user_recommendations(%s, %s)", (user_id, product_id))

            conn.commit()
            return serialize(
                {
                    "success": True,
                    "order_id": order["order_id"],
                    "detail_id": detail["detail_id"],
                    "remaining_stock": remaining_stock,
                    "created_at": order["created_at"],
                }
            )
        except Exception as exc:  # pragma: no cover - defensive rollback path
            conn.rollback()
            return {"success": False, "error": str(exc)}
