DROP MATERIALIZED VIEW IF EXISTS mv_user_rfm_scores;

CREATE MATERIALIZED VIEW mv_user_rfm_scores AS
WITH rfm_base AS (
    SELECT
        u.user_id,
        u.email,
        COALESCE(CURRENT_DATE - MAX(o.created_at)::date, 9999) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        COALESCE(SUM(o.total_amt), 0)::NUMERIC(12, 2) AS monetary
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.user_id
    GROUP BY u.user_id, u.email
),
rfm_scored AS (
    SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC, user_id) AS r_score,
        6 - NTILE(5) OVER (ORDER BY frequency DESC, user_id) AS f_score,
        6 - NTILE(5) OVER (ORDER BY monetary DESC, user_id) AS m_score
    FROM rfm_base
)
SELECT
    user_id,
    email,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 12 THEN 'champions'
        WHEN (r_score + f_score + m_score) >= 9 THEN 'loyal'
        WHEN (r_score + f_score + m_score) >= 6 THEN 'at_risk'
        ELSE 'dormant'
    END AS rfm_tier
FROM rfm_scored;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_user_rfm_scores_user_id
    ON mv_user_rfm_scores(user_id);

CREATE INDEX IF NOT EXISTS idx_rfm_tier
    ON mv_user_rfm_scores(rfm_tier);

CREATE INDEX IF NOT EXISTS idx_rfm_total
    ON mv_user_rfm_scores(rfm_total DESC);

CREATE OR REPLACE FUNCTION fn_refresh_rfm_scores()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_user_rfm_scores;

    UPDATE users u
    SET rfm_tier = r.rfm_tier
    FROM mv_user_rfm_scores r
    WHERE u.user_id = r.user_id;
END;
$$ LANGUAGE plpgsql;
