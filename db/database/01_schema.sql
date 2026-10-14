CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS users (
    user_id     SERIAL PRIMARY KEY,
    email       VARCHAR(255) UNIQUE NOT NULL,
    full_name   VARCHAR(255) NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rfm_tier    VARCHAR(50) NOT NULL DEFAULT 'unscored'
                CHECK (rfm_tier IN ('champions', 'loyal', 'at_risk', 'dormant', 'unscored'))
);

CREATE TABLE IF NOT EXISTS categories (
    category_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    parent_id     INT REFERENCES categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uq_categories_name_parent UNIQUE (name, parent_id)
);

CREATE TABLE IF NOT EXISTS products (
    product_id    SERIAL PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    price         NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    category_id   INT NOT NULL REFERENCES categories(category_id),
    brand         VARCHAR(100),
    stock         INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    attributes    JSONB NOT NULL DEFAULT '{}'::jsonb,
    embedding     VECTOR(384),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS electronics (
    product_id       INT PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    warranty_months  INT CHECK (warranty_months IS NULL OR warranty_months >= 0),
    power_watts      NUMERIC(8, 2) CHECK (power_watts IS NULL OR power_watts >= 0)
);

CREATE TABLE IF NOT EXISTS apparel (
    product_id  INT PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    size        VARCHAR(20),
    material    VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS accessories (
    product_id  INT PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    size        VARCHAR(50),
    material    VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS furniture (
    product_id  INT PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    size        VARCHAR(50),
    material    VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS personal_care (
    product_id  INT PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
    size        VARCHAR(50),
    material    VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS category_complements (
    source_category_id  INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    target_category_id  INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    complement_score    NUMERIC(5, 4) NOT NULL CHECK (complement_score >= 0 AND complement_score <= 1),
    PRIMARY KEY (source_category_id, target_category_id),
    CHECK (source_category_id <> target_category_id)
);

CREATE TABLE IF NOT EXISTS complementary_pairs (
    pair_id           SERIAL PRIMARY KEY,
    product_id        INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    complement_id     INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    lift_score        NUMERIC(8, 4) NOT NULL,
    confidence        NUMERIC(5, 4) NOT NULL,
    support           NUMERIC(5, 4) NOT NULL,
    embedding_sim     NUMERIC(5, 4),
    price_affinity    NUMERIC(5, 4),
    composite_score   NUMERIC(5, 4) NOT NULL,
    pair_type         VARCHAR(50),
    last_updated      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, complement_id),
    CHECK (product_id <> complement_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id    SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(user_id),
    total_amt   NUMERIC(12, 2) NOT NULL CHECK (total_amt >= 0),
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_details (
    detail_id    SERIAL PRIMARY KEY,
    order_id     INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id   INT NOT NULL REFERENCES products(product_id),
    quantity     INT NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    category_id  INT NOT NULL REFERENCES categories(category_id)
);

CREATE TABLE IF NOT EXISTS recommendations (
    rec_id          SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    product_id      INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    match_score     NUMERIC(5, 4) NOT NULL DEFAULT 0,
    generated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    seen_flag       BOOLEAN NOT NULL DEFAULT FALSE,
    clicked_flag    BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (user_id, product_id)
);

CREATE TABLE IF NOT EXISTS recommendation_queue (
    queue_id     SERIAL PRIMARY KEY,
    product_id   INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'processing', 'done', 'failed')),
    error_msg    TEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_similarity (
    product_id_1       INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    product_id_2       INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    similarity_score   NUMERIC(5, 4) NOT NULL CHECK (similarity_score >= 0 AND similarity_score <= 1),
    source             VARCHAR(30) NOT NULL DEFAULT 'content',
    updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id_1, product_id_2),
    CHECK (product_id_1 <> product_id_2)
);

CREATE TABLE IF NOT EXISTS product_launch_audit (
    audit_id       SERIAL PRIMARY KEY,
    product_id     INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    inserted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    inserted_by    TEXT NOT NULL DEFAULT CURRENT_USER
);

CREATE OR REPLACE FUNCTION fn_touch_queue_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_queue_updated_at ON recommendation_queue;
CREATE TRIGGER trg_touch_queue_updated_at
BEFORE UPDATE ON recommendation_queue
FOR EACH ROW
EXECUTE FUNCTION fn_touch_queue_updated_at();
