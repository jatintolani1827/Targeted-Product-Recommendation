from __future__ import annotations

from typing import Any

from flask import Flask, jsonify, request
from flask_cors import CORS
from psycopg2.extras import RealDictCursor

from backend.config import settings
from backend.db import fetch_all, fetch_one, get_connection, serialize, to_json
from backend.purchase_handler import process_purchase
from ml.full_pipeline import refresh_all_user_recommendations


app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": settings.frontend_origin}})

CATEGORY_TREE_SQL = """
WITH RECURSIVE category_tree AS (
    SELECT
        category_id,
        name,
        parent_id,
        name::TEXT AS path,
        0 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.category_id,
        c.name,
        c.parent_id,
        ct.path || ' / ' || c.name AS path,
        ct.depth + 1 AS depth
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.category_id
),
child_counts AS (
    SELECT parent_id, COUNT(*) AS child_count
    FROM categories
    WHERE parent_id IS NOT NULL
    GROUP BY parent_id
)
SELECT
    ct.category_id,
    ct.name,
    ct.parent_id,
    ct.path,
    ct.depth,
    COALESCE(cc.child_count, 0) AS child_count,
    COALESCE(cc.child_count, 0) = 0 AS is_leaf
FROM category_tree ct
LEFT JOIN child_counts cc ON cc.parent_id = ct.category_id
"""

ELECTRONICS_CATEGORY_NAMES = {
    "audio",
    "headphones",
    "speakers",
    "computers",
    "keyboards",
    "smart home",
    "mice",
    "monitors",
    "laptop cooling pads",
    "printers",
    "smartphones",
    "laptops",
    "webcams",
    "microphones",
}

ACCESSORY_CATEGORY_NAMES = {
    "computer accessories",
    "mouse pads",
    "wrist rests",
    "workspace setup",
    "monitor arms",
    "laptop setup",
    "laptop stands",
    "desk organization",
    "cable management",
    "headphone hangers",
    "ink bottles",
    "screen protectors",
    "phone cases",
    "necklaces",
    "bracelets",
    "rings",
    "jewelry",
}

PERSONAL_CARE_CATEGORY_NAMES = {
    "personal care",
    "toothpaste",
    "toothbrushes",
    "mouthwash",
    "dental floss",
}

SUBCLASS_LABELS = {
    "electronics": "Electronics",
    "apparel": "Apparel",
    "accessories": "Accessories",
    "furniture": "Furniture",
    "personal_care": "Personal Care",
    "": "General",
}


def _allowed_subclasses_for_category(path: str, is_leaf: bool) -> list[str]:
    if not is_leaf:
        return []

    segments = [segment.strip().lower() for segment in path.split("/") if segment.strip()]
    if not segments:
        return [""]

    root = segments[0]
    leaf = segments[-1]

    if root == "apparel":
        return ["apparel"]
    if root == "office furniture":
        return ["furniture"]
    if root == "personal care" or leaf in PERSONAL_CARE_CATEGORY_NAMES:
        return ["personal_care"]
    if root == "desk organization":
        return ["accessories"]
    if leaf in ACCESSORY_CATEGORY_NAMES:
        return ["accessories"]
    if leaf in ELECTRONICS_CATEGORY_NAMES or root == "electronics":
        return ["electronics"]
    return [""]


def _decorate_category_row(row: dict[str, Any]) -> dict[str, Any]:
    allowed_subclasses = _allowed_subclasses_for_category(row["path"], row["is_leaf"])
    row["allowed_subclasses"] = allowed_subclasses
    row["default_subclass"] = allowed_subclasses[0] if len(allowed_subclasses) == 1 else ""
    row["subclass_labels"] = {
        subclass: SUBCLASS_LABELS.get(subclass, subclass.title() or "General")
        for subclass in allowed_subclasses
    }
    return row


def _fetch_category(cur, category_id: int) -> dict[str, Any] | None:
    cur.execute(f"{CATEGORY_TREE_SQL} WHERE ct.category_id = %s", (category_id,))
    row = cur.fetchone()
    if not row:
        return None
    return _decorate_category_row(row)


def _recalculate_order_after_detail_changes(cur, order_id: int) -> None:
    cur.execute(
        """
        SELECT COALESCE(SUM(quantity * unit_price), 0) AS total_amt,
               COUNT(*) AS line_count
        FROM order_details
        WHERE order_id = %s
        """,
        (order_id,),
    )
    order_summary = cur.fetchone()

    if order_summary["line_count"] == 0:
        cur.execute("DELETE FROM orders WHERE order_id = %s", (order_id,))
    else:
        cur.execute(
            """
            UPDATE orders
            SET total_amt = %s
            WHERE order_id = %s
            """,
            (order_summary["total_amt"], order_id),
        )


def _refresh_impacted_users(cur, user_ids: set[int]) -> None:
    if not user_ids:
        return

    cur.execute("SELECT fn_refresh_rfm_scores()")
    for user_id in sorted(user_ids):
        cur.execute("CALL sp_refresh_user_recommendations(%s, NULL)", (user_id,))


@app.errorhandler(Exception)
def handle_exception(exc: Exception):
    return jsonify({"error": str(exc)}), 500


@app.get("/api/health")
def healthcheck():
    return jsonify({"status": "ok"})


@app.get("/api/categories")
def get_categories():
    rows = fetch_all(f"{CATEGORY_TREE_SQL} ORDER BY ct.path")
    return jsonify([_decorate_category_row(row) for row in rows])


@app.get("/api/products")
def get_products():
    rows = fetch_all(
        """
        SELECT
            p.product_id,
            p.name,
            p.price,
            c.name AS category,
            p.brand,
            p.stock,
            p.stock > 0 AS in_stock,
            p.attributes,
            p.created_at
        FROM products p
        JOIN categories c ON c.category_id = p.category_id
        ORDER BY p.created_at DESC
        LIMIT 100
        """
    )
    return jsonify(rows)


@app.get("/api/recommendations")
def get_recommendations():
    user_id = request.args.get("user_id", type=int)
    if not user_id:
        return jsonify({"error": "user_id is required"}), 400

    rows = fetch_all(
        """
        SELECT
            p.product_id,
            p.name,
            p.price,
            p.brand,
            c.name AS category,
            p.stock,
            r.match_score,
            r.generated_at,
            CASE
                WHEN comp.pair_type IS NOT NULL THEN 'complementary'
                ELSE 'similar'
            END AS rec_type,
            comp.pair_type,
            CASE
                WHEN comp.pair_type = 'accessory' THEN 'Complete Your Setup'
                WHEN comp.pair_type = 'consumable' THEN 'You Will Need This'
                WHEN comp.pair_type = 'service' THEN 'Pairs Well With'
                WHEN comp.pair_type = 'bundle' THEN 'Frequently Bought Together'
                ELSE 'Recommended For You'
            END AS display_label
        FROM recommendations r
        JOIN products p ON p.product_id = r.product_id
        JOIN categories c ON c.category_id = p.category_id
        LEFT JOIN LATERAL (
            SELECT
                COALESCE(cp.pair_type, 'accessory') AS pair_type,
                GREATEST(
                    COALESCE(cp.composite_score, 0),
                    COALESCE(cc.complement_score, 0)
                ) AS rec_strength,
                o.created_at
            FROM orders o
            JOIN order_details od ON od.order_id = o.order_id
            LEFT JOIN complementary_pairs cp
                ON cp.product_id = od.product_id
               AND cp.complement_id = r.product_id
            LEFT JOIN category_complements cc
                ON cc.source_category_id = od.category_id
               AND cc.target_category_id = p.category_id
            WHERE o.user_id = r.user_id
              AND (
                    cp.product_id IS NOT NULL
                 OR cc.source_category_id IS NOT NULL
              )
            ORDER BY rec_strength DESC, o.created_at DESC
            LIMIT 1
        ) comp ON TRUE
        WHERE r.user_id = %s
          AND r.seen_flag = FALSE
        ORDER BY
            CASE WHEN comp.pair_type IS NOT NULL THEN 0 ELSE 1 END,
            r.match_score DESC,
            r.generated_at DESC
        LIMIT 15
        """,
        (user_id,),
    )
    return jsonify(rows)


@app.get("/api/admin/recommendations")
def get_admin_recommendations():
    limit = request.args.get("limit", default=20, type=int)
    rows = fetch_all(
        """
        SELECT *
        FROM vw_admin_recommendations
        ORDER BY generated_at DESC
        LIMIT %s
        """,
        (limit,),
        admin=True,
    )
    return jsonify(rows)


@app.get("/api/admin/orders")
def get_admin_orders():
    limit = request.args.get("limit", default=100, type=int)
    rows = fetch_all(
        """
        SELECT
            od.detail_id,
            o.order_id,
            o.user_id,
            u.full_name,
            u.email,
            p.product_id,
            p.name AS product_name,
            p.brand,
            c.name AS category,
            od.quantity,
            od.unit_price,
            o.total_amt,
            o.created_at
        FROM order_details od
        JOIN orders o ON o.order_id = od.order_id
        JOIN users u ON u.user_id = o.user_id
        JOIN products p ON p.product_id = od.product_id
        JOIN categories c ON c.category_id = od.category_id
        ORDER BY o.created_at DESC, o.order_id DESC, od.detail_id DESC
        LIMIT %s
        """,
        (limit,),
        admin=True,
    )
    return jsonify(rows)


@app.delete("/api/admin/orders/<int:detail_id>")
def delete_admin_order_entry(detail_id: int):
    with get_connection(admin=True) as conn:
        conn.autocommit = False
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(
                    """
                    SELECT
                        od.detail_id,
                        od.order_id,
                        od.product_id,
                        od.quantity,
                        od.unit_price,
                        o.user_id
                    FROM order_details od
                    JOIN orders o ON o.order_id = od.order_id
                    WHERE od.detail_id = %s
                    FOR UPDATE
                    """,
                    (detail_id,),
                )
                detail = cur.fetchone()
                if not detail:
                    conn.rollback()
                    return jsonify({"error": "Order history entry not found"}), 404

                cur.execute(
                    """
                    SELECT stock
                    FROM products
                    WHERE product_id = %s
                    FOR UPDATE
                    """,
                    (detail["product_id"],),
                )
                product = cur.fetchone()
                if not product:
                    conn.rollback()
                    return jsonify({"error": "Referenced product not found"}), 404

                cur.execute(
                    """
                    UPDATE products
                    SET stock = stock + %s
                    WHERE product_id = %s
                    RETURNING stock
                    """,
                    (detail["quantity"], detail["product_id"]),
                )
                restored_stock = cur.fetchone()["stock"]

                cur.execute(
                    """
                    DELETE FROM dw.fact_interactions
                    WHERE source_detail_id = %s
                    """,
                    (detail_id,),
                )
                cur.execute("DELETE FROM order_details WHERE detail_id = %s", (detail_id,))
                _recalculate_order_after_detail_changes(cur, detail["order_id"])

                cur.execute(
                    """
                    DELETE FROM recommendations
                    WHERE user_id = %s
                      AND product_id = %s
                      AND seen_flag = TRUE
                      AND clicked_flag = TRUE
                    """,
                    (detail["user_id"], detail["product_id"]),
                )
                _refresh_impacted_users(cur, {detail["user_id"]})

            conn.commit()
            return jsonify(
                serialize(
                    {
                        "message": "Order history entry deleted",
                        "detail_id": detail_id,
                        "order_id": detail["order_id"],
                        "user_id": detail["user_id"],
                        "product_id": detail["product_id"],
                        "restored_stock": restored_stock,
                    }
                )
            )
        except Exception as exc:
            conn.rollback()
            return jsonify({"error": str(exc)}), 400


@app.delete("/api/admin/products/<int:product_id>")
def delete_admin_product(product_id: int):
    with get_connection(admin=True) as conn:
        conn.autocommit = False
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(
                    """
                    SELECT product_id, name
                    FROM products
                    WHERE product_id = %s
                    FOR UPDATE
                    """,
                    (product_id,),
                )
                product = cur.fetchone()
                if not product:
                    conn.rollback()
                    return jsonify({"error": "Product not found"}), 404

                cur.execute(
                    """
                    SELECT DISTINCT o.user_id
                    FROM orders o
                    JOIN order_details od ON od.order_id = o.order_id
                    WHERE od.product_id = %s
                    """,
                    (product_id,),
                )
                purchasing_users = {row["user_id"] for row in cur.fetchall()}

                cur.execute(
                    """
                    SELECT DISTINCT user_id
                    FROM recommendations
                    WHERE product_id = %s
                    """,
                    (product_id,),
                )
                recommended_users = {row["user_id"] for row in cur.fetchall()}
                impacted_users = purchasing_users | recommended_users

                cur.execute(
                    """
                    SELECT od.detail_id, od.order_id
                    FROM order_details od
                    WHERE od.product_id = %s
                    FOR UPDATE
                    """,
                    (product_id,),
                )
                impacted_details = cur.fetchall()
                impacted_detail_ids = [row["detail_id"] for row in impacted_details]
                impacted_order_ids = {row["order_id"] for row in impacted_details}

                if impacted_detail_ids:
                    cur.execute(
                        """
                        DELETE FROM dw.fact_interactions
                        WHERE source_detail_id = ANY(%s)
                        """,
                        (impacted_detail_ids,),
                    )

                cur.execute(
                    """
                    DELETE FROM dw.fact_interactions
                    WHERE product_sk IN (
                        SELECT product_sk
                        FROM dw.dim_product
                        WHERE product_id = %s
                    )
                    """,
                    (product_id,),
                )
                cur.execute("DELETE FROM dw.dim_product WHERE product_id = %s", (product_id,))

                if impacted_detail_ids:
                    cur.execute("DELETE FROM order_details WHERE product_id = %s", (product_id,))
                    for order_id in sorted(impacted_order_ids):
                        _recalculate_order_after_detail_changes(cur, order_id)

                cur.execute("DELETE FROM products WHERE product_id = %s", (product_id,))
                _refresh_impacted_users(cur, impacted_users)

            conn.commit()
            return jsonify(
                serialize(
                    {
                        "message": "Product deleted",
                        "product_id": product_id,
                        "product_name": product["name"],
                        "deleted_order_entries": len(impacted_detail_ids),
                        "impacted_users": len(impacted_users),
                    }
                )
            )
        except Exception as exc:
            conn.rollback()
            return jsonify({"error": str(exc)}), 400


@app.get("/api/rfm-stats")
def get_rfm_stats():
    rows = fetch_all(
        """
        SELECT rfm_tier, COUNT(*) AS user_count, ROUND(AVG(rfm_total), 2) AS avg_score
        FROM mv_user_rfm_scores
        GROUP BY rfm_tier
        ORDER BY user_count DESC, rfm_tier
        """,
        admin=True,
    )
    return jsonify(rows)


@app.post("/api/products")
def add_product():
    data: dict[str, Any] = request.get_json(force=True, silent=False) or {}
    required_fields = ("name", "price", "category_id", "stock")
    missing = [field for field in required_fields if field not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    subclass = data.get("subclass")
    with get_connection(admin=False) as conn:
        conn.autocommit = False
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                category = _fetch_category(cur, int(data["category_id"]))
                if not category:
                    conn.rollback()
                    return jsonify({"error": "Category not found"}), 400
                if not category["is_leaf"]:
                    conn.rollback()
                    return jsonify({"error": "Products must be created under a leaf subcategory"}), 400

                allowed_subclasses = category["allowed_subclasses"]
                if subclass is None:
                    subclass = category["default_subclass"] or ""
                if subclass not in allowed_subclasses:
                    allowed_labels = ", ".join(SUBCLASS_LABELS.get(item, item or "General") for item in allowed_subclasses)
                    conn.rollback()
                    return (
                        jsonify(
                            {
                                "error": (
                                    f"Invalid subclass '{subclass or 'general'}' for category "
                                    f"'{category['path']}'. Allowed subclasses: {allowed_labels}"
                                )
                            }
                        ),
                        400,
                    )

                cur.execute(
                    """
                    INSERT INTO products (name, price, category_id, brand, stock, attributes)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING product_id, created_at
                    """,
                    (
                        data["name"],
                        data["price"],
                        category["category_id"],
                        data.get("brand"),
                        data["stock"],
                        to_json(data.get("attributes", {})),
                    ),
                )
                product = cur.fetchone()

                if subclass == "electronics":
                    cur.execute(
                        """
                        INSERT INTO electronics (product_id, warranty_months, power_watts)
                        VALUES (%s, %s, %s)
                        """,
                        (
                            product["product_id"],
                            data.get("warranty_months"),
                            data.get("power_watts"),
                        ),
                    )
                elif subclass == "apparel":
                    cur.execute(
                        """
                        INSERT INTO apparel (product_id, size, material)
                        VALUES (%s, %s, %s)
                        """,
                        (
                            product["product_id"],
                            data.get("size"),
                            data.get("material"),
                        ),
                    )
                elif subclass == "accessories":
                    cur.execute(
                        """
                        INSERT INTO accessories (product_id, size, material)
                        VALUES (%s, %s, %s)
                        """,
                        (
                            product["product_id"],
                            data.get("size"),
                            data.get("material"),
                        ),
                    )
                elif subclass == "furniture":
                    cur.execute(
                        """
                        INSERT INTO furniture (product_id, size, material)
                        VALUES (%s, %s, %s)
                        """,
                        (
                            product["product_id"],
                            data.get("size"),
                            data.get("material"),
                        ),
                    )
                elif subclass == "personal_care":
                    cur.execute(
                        """
                        INSERT INTO personal_care (product_id, size, material)
                        VALUES (%s, %s, %s)
                        """,
                        (
                            product["product_id"],
                            data.get("size"),
                            data.get("material"),
                        ),
                    )

            conn.commit()
            return (
                jsonify(
                    serialize(
                        {
                            "message": "Product created and queued for recommendation generation",
                            "product_id": product["product_id"],
                            "created_at": product["created_at"],
                        }
                    )
                ),
                201,
            )
        except Exception as exc:
            conn.rollback()
            return jsonify({"error": str(exc)}), 400


@app.post("/api/purchase")
def purchase():
    data: dict[str, Any] = request.get_json(force=True, silent=False) or {}
    result = process_purchase(
        user_id=int(data.get("user_id", 0)),
        product_id=int(data.get("product_id", 0)),
        quantity=int(data.get("quantity", 1)),
    )
    status_code = 200 if result.get("success") else 409
    return jsonify(result), status_code


@app.get("/api/purchase-history")
def get_purchase_history():
    user_id = request.args.get("user_id", type=int)
    if not user_id:
        return jsonify({"error": "user_id is required"}), 400

    rows = fetch_all(
        """
        SELECT
            o.order_id,
            o.created_at,
            o.total_amt,
            od.quantity,
            od.unit_price,
            p.product_id,
            p.name,
            p.brand,
            c.name AS category
        FROM orders o
        JOIN order_details od ON od.order_id = o.order_id
        JOIN products p ON p.product_id = od.product_id
        JOIN categories c ON c.category_id = od.category_id
        WHERE o.user_id = %s
        ORDER BY o.created_at DESC, o.order_id DESC, od.detail_id DESC
        LIMIT 50
        """,
        (user_id,),
    )
    return jsonify(rows)


@app.get("/api/users")
def get_users():
    rows = fetch_all(
        """
        SELECT user_id, full_name, email, rfm_tier, created_at
        FROM users
        ORDER BY user_id
        LIMIT 100
        """,
        admin=True,
    )
    return jsonify(rows)


@app.post("/api/rfm-refresh")
def refresh_rfm():
    fetch_one("SELECT fn_refresh_rfm_scores() AS refreshed", admin=True)
    return jsonify({"refreshed": "rfm_scores"})


@app.post("/api/recommendations/refresh-all")
def refresh_all_recommendations():
    refreshed_users = refresh_all_user_recommendations()
    return jsonify({"refreshed_users": refreshed_users})


if __name__ == "__main__":
    app.run(host=settings.api_host, port=settings.api_port, debug=True)
