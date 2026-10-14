from __future__ import annotations

import psycopg2
import pytest


def test_customer_role_cannot_read_users_table(customer_conn):
    with customer_conn.cursor() as cur:
        with pytest.raises(psycopg2.errors.InsufficientPrivilege):
            cur.execute("SELECT rfm_tier FROM users LIMIT 1")
            cur.fetchone()


def test_customer_role_can_read_public_products(customer_conn):
    with customer_conn.cursor() as cur:
        cur.execute("SELECT product_id, name FROM vw_public_products LIMIT 3")
        rows = cur.fetchall()

    assert rows


def test_admin_service_account_can_read_admin_recommendations(admin_conn):
    with admin_conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM vw_admin_recommendations")
        count = cur.fetchone()[0]

    assert count >= 0


def test_analyst_role_can_read_data_warehouse(analyst_conn):
    with analyst_conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM dw.fact_interactions")
        count = cur.fetchone()[0]

    assert count >= 0

