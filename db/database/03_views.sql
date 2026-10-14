DROP VIEW IF EXISTS vw_public_products CASCADE;
CREATE VIEW vw_public_products AS
SELECT
    p.product_id,
    p.name,
    p.price,
    c.name AS category,
    p.brand,
    p.stock > 0 AS in_stock,
    p.attributes,
    p.created_at
FROM products p
JOIN categories c ON c.category_id = p.category_id;

DROP VIEW IF EXISTS vw_my_recommendations CASCADE;
CREATE VIEW vw_my_recommendations AS
SELECT
    r.rec_id,
    r.user_id,
    p.product_id,
    p.name,
    p.price,
    r.match_score,
    r.generated_at,
    r.seen_flag,
    r.clicked_flag
FROM recommendations r
JOIN products p ON p.product_id = r.product_id
WHERE r.user_id = COALESCE(
    (
        SELECT u.user_id
        FROM users u
        WHERE u.email = current_setting('app.current_user_email', true)
        LIMIT 1
    ),
    (
        SELECT u.user_id
        FROM users u
        WHERE u.email = current_user
        LIMIT 1
    )
);

DROP VIEW IF EXISTS vw_admin_recommendations CASCADE;
CREATE VIEW vw_admin_recommendations AS
SELECT
    r.rec_id,
    r.user_id,
    u.email,
    u.full_name,
    u.rfm_tier,
    r.product_id,
    p.name AS product_name,
    p.brand,
    r.match_score,
    r.generated_at,
    r.seen_flag,
    r.clicked_flag
FROM recommendations r
JOIN users u ON u.user_id = r.user_id
JOIN products p ON p.product_id = r.product_id;

