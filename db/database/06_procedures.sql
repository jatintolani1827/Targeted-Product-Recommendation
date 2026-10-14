CREATE OR REPLACE PROCEDURE sp_generate_recommendations(p_product_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_category_id INT;
    v_exists      BOOLEAN;
BEGIN
    SELECT TRUE, category_id
    INTO v_exists, v_category_id
    FROM products
    WHERE product_id = p_product_id;

    IF NOT COALESCE(v_exists, FALSE) THEN
        RAISE EXCEPTION 'Product % does not exist', p_product_id;
    END IF;

    WITH RECURSIVE ancestors AS (
        SELECT c.category_id, c.parent_id
        FROM categories c
        WHERE c.category_id = v_category_id

        UNION ALL

        SELECT parent.category_id, parent.parent_id
        FROM categories parent
        JOIN ancestors a ON a.parent_id = parent.category_id
    ),
    descendants AS (
        SELECT c.category_id, c.parent_id
        FROM categories c
        WHERE c.category_id = v_category_id

        UNION ALL

        SELECT child.category_id, child.parent_id
        FROM categories child
        JOIN descendants d ON child.parent_id = d.category_id
    ),
    siblings AS (
        SELECT sibling.category_id
        FROM categories current_category
        JOIN categories sibling
          ON sibling.parent_id = current_category.parent_id
        WHERE current_category.category_id = v_category_id
          AND current_category.parent_id IS NOT NULL
    ),
    related_categories AS (
        SELECT category_id FROM ancestors
        UNION
        SELECT category_id FROM descendants
        UNION
        SELECT category_id FROM siblings
    ),
    target_users AS (
        SELECT
            o.user_id,
            MAX(
                GREATEST(
                    COALESCE(ps.similarity_score, 0),
                    COALESCE(cp_target.composite_score, 0),
                    COALESCE(cc.complement_score, 0),
                    CASE
                        WHEN hp.category_id IN (SELECT DISTINCT category_id FROM related_categories) THEN 0.45
                        ELSE 0
                    END
                )
            ) AS affinity_score,
            COUNT(*) AS matching_events
        FROM orders o
        JOIN order_details od ON od.order_id = o.order_id
        JOIN products hp ON hp.product_id = od.product_id
        LEFT JOIN product_similarity ps
            ON ps.product_id_1 = p_product_id
           AND ps.product_id_2 = hp.product_id
           AND ps.source <> 'complementary'
        LEFT JOIN complementary_pairs cp_target
            ON cp_target.product_id = hp.product_id
           AND cp_target.complement_id = p_product_id
        LEFT JOIN category_complements cc
            ON cc.source_category_id = hp.category_id
           AND cc.target_category_id = v_category_id
        WHERE (
                hp.category_id IN (SELECT DISTINCT category_id FROM related_categories)
             OR cp_target.product_id IS NOT NULL
             OR cc.source_category_id IS NOT NULL
        )
          AND NOT EXISTS (
              SELECT 1
              FROM orders o_recent
              JOIN order_details od_recent ON od_recent.order_id = o_recent.order_id
              WHERE o_recent.user_id = o.user_id
                AND od_recent.category_id = v_category_id
                AND o_recent.created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
        GROUP BY o.user_id
    ),
    top_value_users AS (
        SELECT r.user_id, r.rfm_total
        FROM mv_user_rfm_scores r
        WHERE r.rfm_tier IN ('champions', 'loyal')
    ),
    scored_targets AS (
        SELECT
            tu.user_id,
            tv.rfm_total,
            ROUND(
                LEAST(
                    1.0,
                    ((tv.rfm_total / 15.0) * 0.65) +
                    (tu.affinity_score * 0.30) +
                    (LEAST(tu.matching_events, 5) / 5.0 * 0.05)
                )::NUMERIC,
                4
            ) AS match_score
        FROM target_users tu
        JOIN top_value_users tv ON tv.user_id = tu.user_id
    )
    INSERT INTO recommendations (user_id, product_id, match_score, generated_at)
    SELECT
        st.user_id,
        p_product_id,
        st.match_score,
        CURRENT_TIMESTAMP
    FROM scored_targets st
    ON CONFLICT (user_id, product_id)
    DO UPDATE SET
        match_score = EXCLUDED.match_score,
        generated_at = CURRENT_TIMESTAMP;

    WITH scored_targets AS (
        SELECT
            r.user_id,
            m.rfm_total
        FROM recommendations r
        JOIN mv_user_rfm_scores m ON m.user_id = r.user_id
        WHERE r.product_id = p_product_id
          AND m.rfm_tier IN ('champions', 'loyal')
    ),
    complement_targets AS (
        SELECT
            cp.complement_id AS product_id,
            MAX(cp.composite_score) AS complement_score
        FROM complementary_pairs cp
        JOIN products p_comp ON p_comp.product_id = cp.complement_id
        WHERE cp.product_id = p_product_id
          AND cp.composite_score > 0.4
          AND p_comp.stock > 0
        GROUP BY cp.complement_id
    )
    INSERT INTO recommendations (user_id, product_id, match_score, generated_at)
    SELECT
        st.user_id,
        ct.product_id,
        ROUND(
            LEAST(
                1.0,
                ((st.rfm_total / 15.0) * 0.5) + (ct.complement_score * 0.5)
            )::NUMERIC,
            4
        ) AS match_score,
        CURRENT_TIMESTAMP
    FROM scored_targets st
    JOIN complement_targets ct ON TRUE
    ON CONFLICT (user_id, product_id)
    DO UPDATE SET
        match_score = GREATEST(recommendations.match_score, EXCLUDED.match_score),
        generated_at = CURRENT_TIMESTAMP;

    UPDATE recommendation_queue
    SET status = 'done',
        error_msg = NULL
    WHERE product_id = p_product_id
      AND status = 'processing';
EXCEPTION
    WHEN OTHERS THEN
        UPDATE recommendation_queue
        SET status = 'failed',
            error_msg = SQLERRM
        WHERE product_id = p_product_id
          AND status = 'processing';
        RAISE;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_refresh_user_recommendations(
    p_user_id INT,
    p_context_product_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    -- Clear the active recommendation shelf for this user before regenerating it.
    DELETE FROM recommendations
    WHERE user_id = p_user_id
      AND seen_flag = FALSE
      AND clicked_flag = FALSE;

    WITH purchased_products AS (
        SELECT DISTINCT
            od.product_id,
            od.category_id,
            o.created_at
        FROM orders o
        JOIN order_details od ON od.order_id = o.order_id
        WHERE o.user_id = p_user_id
    ),
    user_value AS (
        SELECT
            LEAST(
                1.0,
                (
                    CASE
                        WHEN profile.recency_days <= 7 THEN 1.0
                        WHEN profile.recency_days <= 30 THEN 0.9
                        WHEN profile.recency_days <= 90 THEN 0.75
                        WHEN profile.recency_days <= 180 THEN 0.55
                        ELSE 0.35
                    END * 0.35
                ) +
                (LEAST(profile.frequency / 10.0, 1.0) * 0.30) +
                (LEAST(profile.monetary / 100000.0, 1.0) * 0.35)
            ) AS user_weight
        FROM (
            SELECT
                COALESCE(EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(o.created_at)), 365) AS recency_days,
                COUNT(DISTINCT o.order_id) AS frequency,
                COALESCE(SUM(o.total_amt), 0) AS monetary
            FROM orders o
            WHERE o.user_id = p_user_id
        ) profile
    ),
    candidate_scores AS (
        SELECT
            p.product_id,
            MAX(
                GREATEST(
                    COALESCE(ps_forward.similarity_score, 0),
                    COALESCE(ps_reverse.similarity_score, 0),
                    COALESCE(cp_forward.composite_score, 0),
                    COALESCE(cc.complement_score, 0),
                    CASE
                        WHEN p.category_id = pp.category_id THEN 0.35
                        WHEN candidate_category.parent_id IS NOT NULL
                             AND candidate_category.parent_id = purchased_category.parent_id THEN 0.28
                        WHEN candidate_category.parent_id = pp.category_id
                             OR purchased_category.parent_id = p.category_id THEN 0.22
                        ELSE 0
                    END
                )
            ) AS affinity_score,
            SUM(
                CASE
                    WHEN p.category_id = pp.category_id THEN 1
                    WHEN cp_forward.product_id IS NOT NULL THEN 1
                    WHEN cc.source_category_id IS NOT NULL THEN 1
                    WHEN candidate_category.parent_id IS NOT NULL
                         AND candidate_category.parent_id = purchased_category.parent_id THEN 1
                    WHEN candidate_category.parent_id = pp.category_id
                         OR purchased_category.parent_id = p.category_id THEN 1
                    ELSE 0
                END
            ) AS category_hits,
            MAX(
                CASE
                    WHEN p_context_product_id IS NOT NULL
                         AND pp.product_id = p_context_product_id THEN
                        GREATEST(
                            COALESCE(ps_forward.similarity_score, 0),
                            COALESCE(ps_reverse.similarity_score, 0),
                            COALESCE(cp_forward.composite_score, 0),
                            COALESCE(cc.complement_score, 0),
                            CASE
                                WHEN p.category_id = pp.category_id THEN 0.35
                                WHEN candidate_category.parent_id IS NOT NULL
                                     AND candidate_category.parent_id = purchased_category.parent_id THEN 0.28
                                WHEN candidate_category.parent_id = pp.category_id
                                     OR purchased_category.parent_id = p.category_id THEN 0.22
                                ELSE 0
                            END
                        )
                    ELSE 0
                END
            ) AS context_score
        FROM products p
        JOIN purchased_products pp ON TRUE
        JOIN categories candidate_category ON candidate_category.category_id = p.category_id
        JOIN categories purchased_category ON purchased_category.category_id = pp.category_id
        LEFT JOIN complementary_pairs cp_forward
            ON cp_forward.product_id = pp.product_id
           AND cp_forward.complement_id = p.product_id
        LEFT JOIN category_complements cc
            ON cc.source_category_id = pp.category_id
           AND cc.target_category_id = p.category_id
        LEFT JOIN product_similarity ps_forward
            ON ps_forward.product_id_1 = pp.product_id
           AND ps_forward.product_id_2 = p.product_id
           AND ps_forward.source <> 'complementary'
        LEFT JOIN product_similarity ps_reverse
            ON ps_reverse.product_id_2 = pp.product_id
           AND ps_reverse.product_id_1 = p.product_id
           AND ps_reverse.source <> 'complementary'
        WHERE p.stock > 0
          AND NOT EXISTS (
              SELECT 1
              FROM purchased_products owned
              WHERE owned.product_id = p.product_id
          )
        GROUP BY p.product_id
    ),
    ranked_candidates AS (
        SELECT
            cs.product_id,
            ROUND(
                LEAST(
                    1.0,
                    (cs.affinity_score * 0.60) +
                    (LEAST(cs.category_hits, 5) / 5.0 * 0.15) +
                    (cs.context_score * 0.15) +
                    (uv.user_weight * 0.10)
                )::NUMERIC,
                4
            ) AS match_score
        FROM candidate_scores cs
        CROSS JOIN user_value uv
        WHERE cs.affinity_score > 0
           OR cs.category_hits > 0
           OR cs.context_score > 0
    )
    INSERT INTO recommendations (user_id, product_id, match_score, generated_at, seen_flag, clicked_flag)
    SELECT
        p_user_id,
        rc.product_id,
        rc.match_score,
        CURRENT_TIMESTAMP,
        FALSE,
        FALSE
    FROM ranked_candidates rc
    ORDER BY rc.match_score DESC, rc.product_id
    LIMIT 10
    ON CONFLICT (user_id, product_id)
    DO UPDATE SET
        match_score = EXCLUDED.match_score,
        generated_at = CURRENT_TIMESTAMP,
        seen_flag = FALSE,
        clicked_flag = FALSE;
END;
$$;
