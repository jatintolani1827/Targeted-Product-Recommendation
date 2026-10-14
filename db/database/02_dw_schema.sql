CREATE SCHEMA IF NOT EXISTS dw;

CREATE TABLE IF NOT EXISTS dw.dim_user (
    user_sk     SERIAL PRIMARY KEY,
    user_id     INT UNIQUE NOT NULL,
    email       VARCHAR(255),
    full_name   VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS dw.dim_product (
    product_sk  SERIAL PRIMARY KEY,
    product_id  INT UNIQUE NOT NULL,
    name        VARCHAR(255),
    category    VARCHAR(100),
    brand       VARCHAR(100),
    price       NUMERIC(10, 2)
);

CREATE TABLE IF NOT EXISTS dw.dim_time (
    time_sk      SERIAL PRIMARY KEY,
    full_date    DATE UNIQUE NOT NULL,
    day_of_week  INT NOT NULL,
    month        INT NOT NULL,
    quarter      INT NOT NULL,
    year         INT NOT NULL
);

CREATE TABLE IF NOT EXISTS dw.fact_interactions (
    interaction_id     SERIAL PRIMARY KEY,
    source_detail_id   INT UNIQUE NOT NULL,
    source_order_id    INT NOT NULL,
    user_sk            INT NOT NULL REFERENCES dw.dim_user(user_sk),
    product_sk         INT NOT NULL REFERENCES dw.dim_product(product_sk),
    time_sk            INT NOT NULL REFERENCES dw.dim_time(time_sk),
    quantity           INT NOT NULL,
    total_spent        NUMERIC(12, 2) NOT NULL
);

