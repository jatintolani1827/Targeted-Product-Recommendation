from __future__ import annotations

from psycopg2.extras import RealDictCursor

from backend.app import app
from backend.purchase_handler import process_purchase


def test_categories_endpoint_returns_leaf_subclass_metadata():
    with app.test_client() as client:
        response = client.get("/api/categories")

    assert response.status_code == 200
    payload = response.get_json()

    footwear = next(category for category in payload if category["name"] == "Footwear")
    mouse_pads = next(category for category in payload if category["name"] == "Mouse Pads")
    toothpaste = next(category for category in payload if category["name"] == "Toothpaste")
    printers = next(category for category in payload if category["name"] == "Printers")

    assert footwear["is_leaf"] is True
    assert footwear["allowed_subclasses"] == ["apparel"]
    assert mouse_pads["is_leaf"] is True
    assert mouse_pads["allowed_subclasses"] == ["accessories"]
    assert toothpaste["is_leaf"] is True
    assert toothpaste["allowed_subclasses"] == ["personal_care"]
    assert printers["is_leaf"] is True
    assert printers["allowed_subclasses"] == ["electronics"]


def test_admin_can_delete_order_history_entry_and_restore_stock(admin_conn):
    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT stock FROM products WHERE product_id = 1")
        original_stock = cur.fetchone()["stock"]

    purchase_result = process_purchase(user_id=1, product_id=1, quantity=1)
    assert purchase_result["success"] is True

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT
                od.detail_id,
                od.order_id,
                od.product_id,
                od.quantity
            FROM order_details od
            WHERE od.detail_id = %s
            """,
            (purchase_result["detail_id"],),
        )
        entry = cur.fetchone()

    assert entry is not None

    with app.test_client() as client:
        response = client.delete(f"/api/admin/orders/{entry['detail_id']}")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["detail_id"] == entry["detail_id"]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT 1 FROM order_details WHERE detail_id = %s", (entry["detail_id"],))
        deleted_entry = cur.fetchone()

        cur.execute("SELECT stock FROM products WHERE product_id = %s", (entry["product_id"],))
        updated_product = cur.fetchone()

        cur.execute("SELECT 1 FROM orders WHERE order_id = %s", (entry["order_id"],))
        remaining_order = cur.fetchone()

    assert deleted_entry is None
    assert updated_product is not None
    assert updated_product["stock"] == original_stock
    assert remaining_order is None


def test_admin_can_delete_product_and_cleanup_history(admin_conn):
    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            INSERT INTO products (name, price, category_id, brand, stock, attributes)
            VALUES ('Admin Delete Product', 12345, 3, 'Admin Brand', 4, '{"admin_delete": true}'::jsonb)
            RETURNING product_id
            """
        )
        product_id = cur.fetchone()["product_id"]
    admin_conn.commit()

    purchase_result = process_purchase(user_id=1, product_id=product_id, quantity=1)
    assert purchase_result["success"] is True

    with app.test_client() as client:
        response = client.delete(f"/api/admin/products/{product_id}")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["product_id"] == product_id
    assert payload["deleted_order_entries"] >= 1

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT 1 FROM products WHERE product_id = %s", (product_id,))
        deleted_product = cur.fetchone()

        cur.execute("SELECT 1 FROM order_details WHERE product_id = %s", (product_id,))
        deleted_details = cur.fetchone()

        cur.execute("SELECT 1 FROM orders WHERE order_id = %s", (purchase_result["order_id"],))
        deleted_order = cur.fetchone()

        cur.execute("SELECT 1 FROM dw.dim_product WHERE product_id = %s", (product_id,))
        deleted_dim_product = cur.fetchone()

    assert deleted_product is None
    assert deleted_details is None
    assert deleted_order is None
    assert deleted_dim_product is None


def test_admin_can_create_accessory_product_with_subclass_metadata(admin_conn):
    with app.test_client() as client:
        response = client.post(
            "/api/products",
            json={
                "name": "Accessory Metadata Product",
                "price": 1499,
                "category_id": 11,
                "brand": "Accessory Brand",
                "stock": 9,
                "attributes": {"surface": "cloth"},
                "subclass": "accessories",
                "size": "large",
                "material": "cloth"
            },
        )

    assert response.status_code == 201
    payload = response.get_json()
    product_id = payload["product_id"]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT size, material
            FROM accessories
            WHERE product_id = %s
            """,
            (product_id,),
        )
        accessory_row = cur.fetchone()

    assert accessory_row is not None
    assert accessory_row["size"] == "large"
    assert accessory_row["material"] == "cloth"


def test_admin_can_create_personal_care_product_with_subclass_metadata(admin_conn):
    with app.test_client() as client:
        response = client.post(
            "/api/products",
            json={
                "name": "Personal Care Metadata Product",
                "price": 249,
                "category_id": 31,
                "brand": "Care Brand",
                "stock": 15,
                "attributes": {"flavour": "mint"},
                "subclass": "personal_care",
                "size": "150g",
                "material": "paste"
            },
        )

    assert response.status_code == 201
    payload = response.get_json()
    product_id = payload["product_id"]

    with admin_conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT size, material
            FROM personal_care
            WHERE product_id = %s
            """,
            (product_id,),
        )
        personal_care_row = cur.fetchone()

    assert personal_care_row is not None
    assert personal_care_row["size"] == "150g"
    assert personal_care_row["material"] == "paste"


def test_product_creation_rejects_invalid_subclass_for_leaf_category(admin_conn):
    with app.test_client() as client:
        response = client.post(
            "/api/products",
            json={
                "name": "Invalid Footwear Product",
                "price": 1299,
                "category_id": 7,
                "brand": "Bad Taxonomy",
                "stock": 4,
                "attributes": {"color": "black"},
                "subclass": "electronics",
                "warranty_months": 12,
                "power_watts": 1
            },
        )

    assert response.status_code == 400
    payload = response.get_json()
    assert "Invalid subclass" in payload["error"]
