-- ============================================================
-- 10_test_products.sql  –  20 additional products for testing
-- ============================================================
-- New leaf categories under existing parents
-- ============================================================

INSERT INTO categories (category_id, name, parent_id) VALUES
    (45, 'Speakers',  2),   -- Audio → Speakers
    (46, 'T-Shirts',  6),   -- Apparel → T-Shirts
    (47, 'Jackets',   6)    -- Apparel → Jackets
ON CONFLICT (category_id) DO UPDATE
SET name = EXCLUDED.name,
    parent_id = EXCLUDED.parent_id;

SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));

-- ============================================================
-- 20 test products
-- ============================================================

INSERT INTO products (name, price, category_id, brand, stock, attributes, created_at) VALUES

    -- ── Headphones (category_id = 3) ──────────────────────────
    ('Sennheiser HD 660S2',        39999.00,  3, 'Sennheiser', 12,
     '{"color":"black","wireless":false,"noise_cancelling":false,"type":"open-back"}',
     CURRENT_TIMESTAMP - INTERVAL '45 days'),

    ('JBL Tune 770NC',             6499.00,   3, 'JBL',        45,
     '{"color":"blue","wireless":true,"noise_cancelling":true}',
     CURRENT_TIMESTAMP - INTERVAL '42 days'),

    ('Samsung Galaxy Buds3 Pro',   17999.00,  3, 'Samsung',    30,
     '{"color":"silver","wireless":true,"noise_cancelling":true,"type":"in-ear"}',
     CURRENT_TIMESTAMP - INTERVAL '38 days'),

    -- ── Keyboards (category_id = 5) ──────────────────────────
    ('Royal Kludge RK84',          4999.00,   5, 'Royal Kludge', 55,
     '{"switch":"red","wireless":true,"layout":"75%","hot_swappable":true}',
     CURRENT_TIMESTAMP - INTERVAL '36 days'),

    ('Razer BlackWidow V4',        13999.00,  5, 'Razer',      20,
     '{"switch":"green","wireless":false,"layout":"full","rgb":true}',
     CURRENT_TIMESTAMP - INTERVAL '33 days'),

    -- ── Monitors (category_id = 14) ──────────────────────────
    ('LG UltraGear 27GP850-B',     32999.00, 14, 'LG',         15,
     '{"size_inches":27,"resolution":"2560x1440","refresh_hz":165,"panel":"IPS"}',
     CURRENT_TIMESTAMP - INTERVAL '30 days'),

    ('Samsung Odyssey G5',         24999.00, 14, 'Samsung',    18,
     '{"size_inches":27,"resolution":"2560x1440","refresh_hz":144,"panel":"VA","curved":true}',
     CURRENT_TIMESTAMP - INTERVAL '28 days'),

    ('Dell UltraSharp U2723QE',    44999.00, 14, 'Dell',       10,
     '{"size_inches":27,"resolution":"3840x2160","refresh_hz":60,"panel":"IPS","usb_c":true}',
     CURRENT_TIMESTAMP - INTERVAL '25 days'),

    -- ── Mice (category_id = 10) ──────────────────────────────
    ('Logitech MX Master 3S',      8999.00,  10, 'Logitech',   35,
     '{"dpi":8000,"wireless":true,"ergonomic":true,"buttons":7}',
     CURRENT_TIMESTAMP - INTERVAL '22 days'),

    ('Razer DeathAdder V3',        6999.00,  10, 'Razer',      28,
     '{"dpi":30000,"wireless":false,"ergonomic":true,"weight_g":59}',
     CURRENT_TIMESTAMP - INTERVAL '20 days'),

    -- ── Speakers (category_id = 45) ──────────────────────────
    ('JBL Charge 5',               12999.00, 45, 'JBL',        40,
     '{"waterproof":"IP67","wireless":true,"battery_hours":20}',
     CURRENT_TIMESTAMP - INTERVAL '18 days'),

    ('Sony SRS-XB100',              4499.00, 45, 'Sony',       60,
     '{"waterproof":"IP67","wireless":true,"battery_hours":16,"color":"orange"}',
     CURRENT_TIMESTAMP - INTERVAL '15 days'),

    ('Marshall Stanmore III',      39999.00, 45, 'Marshall',    8,
     '{"wireless":true,"wifi":true,"multi_room":true,"wattage":80}',
     CURRENT_TIMESTAMP - INTERVAL '12 days'),

    -- ── Smart Home (category_id = 8) ─────────────────────────
    ('Amazon Echo Dot 5th Gen',     4999.00,  8, 'Amazon',     65,
     '{"assistant":"alexa","wireless":true,"clock_display":true}',
     CURRENT_TIMESTAMP - INTERVAL '10 days'),

    ('Philips Hue Starter Kit',     9999.00,  8, 'Philips',    25,
     '{"bulbs":3,"bridge":true,"wireless":true,"color_range":"16M"}',
     CURRENT_TIMESTAMP - INTERVAL '8 days'),

    -- ── Footwear (category_id = 7) ───────────────────────────
    ('Puma RS-X Reinvention',       8999.00,  7, 'Puma',       30,
     '{"color":"white/blue","sport":"casual","sole":"rubber"}',
     CURRENT_TIMESTAMP - INTERVAL '7 days'),

    ('New Balance 990v6',          22999.00,  7, 'New Balance', 15,
     '{"color":"grey","sport":"running","made_in":"USA"}',
     CURRENT_TIMESTAMP - INTERVAL '5 days'),

    -- ── T-Shirts (category_id = 46) ──────────────────────────
    ('Uniqlo AIRism Crew Neck',      999.00, 46, 'Uniqlo',     100,
     '{"color":"white","fit":"regular"}',
     CURRENT_TIMESTAMP - INTERVAL '4 days'),

    -- ── Jackets (category_id = 47) ───────────────────────────
    ('The North Face Thermoball',  16999.00, 47, 'The North Face', 20,
     '{"color":"black","insulation":"thermoball","waterproof":true}',
     CURRENT_TIMESTAMP - INTERVAL '3 days'),

    ('Columbia Powder Lite',       12999.00, 47, 'Columbia',   22,
     '{"color":"navy","insulation":"omni-heat","packable":true}',
     CURRENT_TIMESTAMP - INTERVAL '2 days')

ON CONFLICT DO NOTHING;

-- ============================================================
-- Subclass rows — electronics
-- ============================================================

INSERT INTO electronics (product_id, warranty_months, power_watts)
SELECT product_id,
       CASE
           WHEN name IN ('LG UltraGear 27GP850-B','Samsung Odyssey G5','Dell UltraSharp U2723QE') THEN 36
           ELSE 24
       END,
       CASE
           WHEN name IN ('LG UltraGear 27GP850-B') THEN 48.0
           WHEN name IN ('Samsung Odyssey G5')      THEN 42.0
           WHEN name IN ('Dell UltraSharp U2723QE') THEN 32.0
           WHEN name IN ('Marshall Stanmore III')    THEN 80.0
           WHEN name IN ('JBL Charge 5')             THEN 40.0
           ELSE 5.0
       END
FROM products
WHERE name IN (
    'Sennheiser HD 660S2',
    'JBL Tune 770NC',
    'Samsung Galaxy Buds3 Pro',
    'Royal Kludge RK84',
    'Razer BlackWidow V4',
    'LG UltraGear 27GP850-B',
    'Samsung Odyssey G5',
    'Dell UltraSharp U2723QE',
    'Logitech MX Master 3S',
    'Razer DeathAdder V3',
    'JBL Charge 5',
    'Sony SRS-XB100',
    'Marshall Stanmore III',
    'Amazon Echo Dot 5th Gen',
    'Philips Hue Starter Kit'
)
ON CONFLICT (product_id) DO NOTHING;

-- ============================================================
-- Subclass rows — apparel
-- ============================================================

INSERT INTO apparel (product_id, size, material)
SELECT product_id,
       CASE
           WHEN name = 'Puma RS-X Reinvention'      THEN '9'
           WHEN name = 'New Balance 990v6'           THEN '10'
           WHEN name = 'Uniqlo AIRism Crew Neck'     THEN 'M'
           WHEN name = 'The North Face Thermoball'   THEN 'L'
           WHEN name = 'Columbia Powder Lite'        THEN 'L'
       END,
       CASE
           WHEN name = 'Puma RS-X Reinvention'      THEN 'mesh/suede'
           WHEN name = 'New Balance 990v6'           THEN 'pigskin/mesh'
           WHEN name = 'Uniqlo AIRism Crew Neck'     THEN 'polyester/cupro'
           WHEN name = 'The North Face Thermoball'   THEN 'nylon'
           WHEN name = 'Columbia Powder Lite'        THEN 'polyester'
       END
FROM products
WHERE name IN (
    'Puma RS-X Reinvention',
    'New Balance 990v6',
    'Uniqlo AIRism Crew Neck',
    'The North Face Thermoball',
    'Columbia Powder Lite'
)
ON CONFLICT (product_id) DO NOTHING;
