CREATE INDEX IF NOT EXISTS idx_products_category
    ON products(category_id);

CREATE INDEX IF NOT EXISTS idx_products_attributes
    ON products USING GIN (attributes);

CREATE INDEX IF NOT EXISTS idx_products_embedding
    ON products USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_orders_user
    ON orders(user_id);

CREATE INDEX IF NOT EXISTS idx_orders_created
    ON orders(created_at);

CREATE INDEX IF NOT EXISTS idx_od_order
    ON order_details(order_id);

CREATE INDEX IF NOT EXISTS idx_od_product
    ON order_details(product_id);

CREATE INDEX IF NOT EXISTS idx_od_category
    ON order_details(category_id);

CREATE INDEX IF NOT EXISTS idx_recommendations_user_score
    ON recommendations(user_id, match_score DESC);

CREATE INDEX IF NOT EXISTS idx_queue_status_created
    ON recommendation_queue(status, created_at);

CREATE INDEX IF NOT EXISTS idx_similarity_p1
    ON product_similarity(product_id_1, similarity_score DESC);

CREATE INDEX IF NOT EXISTS idx_category_complements_target
    ON category_complements(target_category_id, source_category_id);

CREATE INDEX IF NOT EXISTS idx_cp_product
    ON complementary_pairs(product_id);

CREATE INDEX IF NOT EXISTS idx_cp_score
    ON complementary_pairs(composite_score DESC);

CREATE INDEX IF NOT EXISTS idx_cp_type
    ON complementary_pairs(pair_type);

CREATE INDEX IF NOT EXISTS idx_dim_time_full_date
    ON dw.dim_time(full_date);
