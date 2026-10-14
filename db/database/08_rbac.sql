DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_role') THEN
        CREATE ROLE admin_role NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'customer_role') THEN
        CREATE ROLE customer_role NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst_role') THEN
        CREATE ROLE analyst_role NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user LOGIN PASSWORD 'secure_pass';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'customer_user') THEN
        CREATE ROLE customer_user LOGIN PASSWORD 'secure_pass';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst_user') THEN
        CREATE ROLE analyst_user LOGIN PASSWORD 'secure_pass';
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO admin_role, customer_role, analyst_role;
GRANT USAGE ON SCHEMA dw TO admin_role, analyst_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO admin_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_role;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO admin_role;

GRANT SELECT ON vw_public_products TO customer_role;
GRANT SELECT ON vw_my_recommendations TO customer_role;
GRANT SELECT ON products, categories TO customer_role;
GRANT INSERT ON orders, order_details TO customer_role;
GRANT USAGE, SELECT ON SEQUENCE orders_order_id_seq, order_details_detail_id_seq TO customer_role;

GRANT SELECT ON ALL TABLES IN SCHEMA dw TO analyst_role;
GRANT SELECT ON mv_user_rfm_scores TO analyst_role;

REVOKE DELETE ON orders FROM customer_role;
REVOKE UPDATE ON users FROM customer_role;
REVOKE SELECT ON users FROM customer_role;

GRANT admin_role TO app_user;
GRANT customer_role TO customer_user;
GRANT analyst_role TO analyst_user;
