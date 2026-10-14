INSERT INTO categories (category_id, name, parent_id) VALUES
    (1, 'Electronics', NULL),
    (2, 'Audio', 1),
    (3, 'Headphones', 2),
    (4, 'Computers', 1),
    (5, 'Keyboards', 4),
    (6, 'Apparel', NULL),
    (7, 'Footwear', 6),
    (8, 'Smart Home', 1),
    (9, 'Computer Accessories', 4),
    (10, 'Mice', 9),
    (11, 'Mouse Pads', 9),
    (12, 'Wrist Rests', 9),
    (13, 'Workspace Setup', 4),
    (14, 'Monitors', 13),
    (15, 'Monitor Arms', 13),
    (16, 'Laptop Setup', 4),
    (17, 'Laptop Stands', 16),
    (18, 'Laptop Cooling Pads', 16),
    (19, 'Printers', 1),
    (20, 'Ink Bottles', 1),
    (21, 'Smartphones', 1),
    (22, 'Screen Protectors', 1),
    (23, 'Phone Cases', 1),
    (24, 'Laptops', 4),
    (25, 'Shirts', 6),
    (26, 'Trousers', 6),
    (43, 'Personal Care', NULL),
    (44, 'Jewelry', NULL),
    (27, 'Necklaces', 44),
    (28, 'Bracelets', 44),
    (29, 'Rings', 44),
    (30, 'Socks', 6),
    (31, 'Toothpaste', 43),
    (32, 'Toothbrushes', 43),
    (33, 'Mouthwash', 43),
    (34, 'Dental Floss', 43),
    (35, 'Creator Gear', 4),
    (36, 'Webcams', 35),
    (37, 'Microphones', 35),
    (38, 'Office Furniture', NULL),
    (39, 'Chairs', 38),
    (40, 'Desk Organization', NULL),
    (41, 'Cable Management', 40),
    (42, 'Headphone Hangers', 40)
ON CONFLICT (category_id) DO UPDATE
SET name = EXCLUDED.name,
    parent_id = EXCLUDED.parent_id;

SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));

INSERT INTO users (email, full_name, created_at) VALUES
    ('aarav@example.com', 'Aarav Menon', CURRENT_TIMESTAMP - INTERVAL '320 days'),
    ('diya@example.com', 'Diya Krishnan', CURRENT_TIMESTAMP - INTERVAL '280 days'),
    ('ishaan@example.com', 'Ishaan Sharma', CURRENT_TIMESTAMP - INTERVAL '250 days'),
    ('meera@example.com', 'Meera Iyer', CURRENT_TIMESTAMP - INTERVAL '220 days'),
    ('nisha@example.com', 'Nisha Kapoor', CURRENT_TIMESTAMP - INTERVAL '180 days'),
    ('rohan@example.com', 'Rohan Patel', CURRENT_TIMESTAMP - INTERVAL '150 days'),
    ('sana@example.com', 'Sana Khan', CURRENT_TIMESTAMP - INTERVAL '120 days'),
    ('vivaan@example.com', 'Vivaan Rao', CURRENT_TIMESTAMP - INTERVAL '90 days')
ON CONFLICT (email) DO NOTHING;

INSERT INTO products (name, price, category_id, brand, stock, attributes, created_at) VALUES
    ('Sony WH-1000XM4', 24999.00, 3, 'Sony', 25, '{"color":"black","wireless":true,"noise_cancelling":true}', CURRENT_TIMESTAMP - INTERVAL '120 days'),
    ('Bose QuietComfort 45', 26999.00, 3, 'Bose', 18, '{"color":"white","wireless":true,"noise_cancelling":true}', CURRENT_TIMESTAMP - INTERVAL '110 days'),
    ('Keychron K2', 8999.00, 5, 'Keychron', 30, '{"switch":"brown","wireless":true,"layout":"75%"}', CURRENT_TIMESTAMP - INTERVAL '100 days'),
    ('Logitech MX Keys Mini', 10499.00, 5, 'Logitech', 22, '{"switch":"scissor","wireless":true,"layout":"75%"}', CURRENT_TIMESTAMP - INTERVAL '95 days'),
    ('Nike Pegasus 40', 11999.00, 7, 'Nike', 40, '{"color":"blue","sport":"running"}', CURRENT_TIMESTAMP - INTERVAL '85 days'),
    ('Adidas Ultraboost Light', 14999.00, 7, 'Adidas', 35, '{"color":"white","sport":"running"}', CURRENT_TIMESTAMP - INTERVAL '75 days'),
    ('Google Nest Mini', 4499.00, 8, 'Google', 50, '{"assistant":"google","wireless":true}', CURRENT_TIMESTAMP - INTERVAL '60 days'),
    ('Apple AirPods Pro', 23999.00, 3, 'Apple', 20, '{"color":"white","wireless":true,"noise_cancelling":true}', CURRENT_TIMESTAMP - INTERVAL '50 days'),
    ('Logitech G Pro X Superlight 2', 13999.00, 10, 'Logitech', 20, '{"color":"black","wireless":true,"dpi":32000}', CURRENT_TIMESTAMP - INTERVAL '42 days'),
    ('Razer DeathAdder V3 Pro', 12499.00, 10, 'Razer', 18, '{"color":"white","wireless":true,"dpi":30000}', CURRENT_TIMESTAMP - INTERVAL '40 days'),
    ('SteelSeries QcK Large', 1499.00, 11, 'SteelSeries', 40, '{"color":"black","surface":"micro-woven","size_type":"large"}', CURRENT_TIMESTAMP - INTERVAL '38 days'),
    ('Razer Gigantus V2 Medium', 999.00, 11, 'Razer', 38, '{"color":"black","surface":"textured cloth","size_type":"medium"}', CURRENT_TIMESTAMP - INTERVAL '37 days'),
    ('HyperX Wrist Rest Full Size', 1999.00, 12, 'HyperX', 24, '{"color":"black","support":"ergonomic","keyboard_size":"full-size"}', CURRENT_TIMESTAMP - INTERVAL '35 days'),
    ('Razer Ergonomic Wrist Rest Pro', 2499.00, 12, 'Razer', 16, '{"color":"black","support":"plush","keyboard_size":"full-size"}', CURRENT_TIMESTAMP - INTERVAL '33 days'),
    ('LG UltraGear 27GR75Q', 22999.00, 14, 'LG', 14, '{"size_inches":27,"resolution":"QHD","refresh_rate_hz":165}', CURRENT_TIMESTAMP - INTERVAL '31 days'),
    ('Acer Nitro VG240Y', 10999.00, 14, 'Acer', 22, '{"size_inches":24,"resolution":"FHD","refresh_rate_hz":180}', CURRENT_TIMESTAMP - INTERVAL '29 days'),
    ('North Bayou F80 Monitor Arm', 2499.00, 15, 'North Bayou', 31, '{"mount_type":"single","max_size_inches":30,"gas_spring":true}', CURRENT_TIMESTAMP - INTERVAL '28 days'),
    ('Amazon Basics Dual Monitor Arm', 5999.00, 15, 'Amazon Basics', 13, '{"mount_type":"dual","max_size_inches":27,"gas_spring":true}', CURRENT_TIMESTAMP - INTERVAL '27 days'),
    ('Portronics My Buddy K Laptop Stand', 1299.00, 17, 'Portronics', 36, '{"adjustable":true,"foldable":true,"material_type":"aluminium"}', CURRENT_TIMESTAMP - INTERVAL '26 days'),
    ('MOCA Adjustable Laptop Riser', 1899.00, 17, 'MOCA', 25, '{"adjustable":true,"foldable":true,"material_type":"aluminium"}', CURRENT_TIMESTAMP - INTERVAL '25 days'),
    ('Cooler Master Notepal X150R', 2999.00, 18, 'Cooler Master', 18, '{"fan_count":1,"rgb":true,"adjustable_height":true}', CURRENT_TIMESTAMP - INTERVAL '24 days'),
    ('DeepCool Multi Core X6', 2499.00, 18, 'DeepCool', 21, '{"fan_count":4,"rgb":false,"adjustable_height":true}', CURRENT_TIMESTAMP - INTERVAL '23 days'),
    ('Logitech C920 HD Pro', 6999.00, 36, 'Logitech', 24, '{"resolution":"1080p","microphone":"dual","autofocus":true}', CURRENT_TIMESTAMP - INTERVAL '22 days'),
    ('HP 320 FHD Webcam', 3999.00, 36, 'HP', 30, '{"resolution":"1080p","microphone":"single","privacy_shutter":true}', CURRENT_TIMESTAMP - INTERVAL '21 days'),
    ('HyperX SoloCast', 4999.00, 37, 'HyperX', 29, '{"connection":"USB","pickup_pattern":"cardioid","tap_to_mute":true}', CURRENT_TIMESTAMP - INTERVAL '20 days'),
    ('FIFINE K669B', 3199.00, 37, 'FIFINE', 35, '{"connection":"USB","pickup_pattern":"cardioid","budget":true}', CURRENT_TIMESTAMP - INTERVAL '19 days'),
    ('Green Soul Seoul Mid Back Chair', 8999.00, 39, 'Green Soul', 19, '{"ergonomic":true,"adjustable_height":true,"lumbar_support":true}', CURRENT_TIMESTAMP - INTERVAL '18 days'),
    ('Amazon Basics Cable Management Sleeve', 599.00, 41, 'Amazon Basics', 60, '{"type":"cable_management","reusable":true,"length_cm":150}', CURRENT_TIMESTAMP - INTERVAL '17 days'),
    ('Tizum Under Desk Headphone Hanger', 699.00, 42, 'Tizum', 37, '{"type":"headphone_hanger","under_desk":true,"adhesive_mount":true}', CURRENT_TIMESTAMP - INTERVAL '16 days')
ON CONFLICT DO NOTHING;

INSERT INTO electronics (product_id, warranty_months, power_watts)
SELECT p.product_id, seed.warranty_months, seed.power_watts
FROM products p
JOIN (
    VALUES
        ('Sony WH-1000XM4', 24, 5.0::NUMERIC),
        ('Bose QuietComfort 45', 24, 5.0::NUMERIC),
        ('Keychron K2', 24, 5.0::NUMERIC),
        ('Logitech MX Keys Mini', 24, 4.0::NUMERIC),
        ('Google Nest Mini', 12, 8.0::NUMERIC),
        ('Apple AirPods Pro', 12, 4.0::NUMERIC),
        ('Logitech G Pro X Superlight 2', 24, 2.0::NUMERIC),
        ('Razer DeathAdder V3 Pro', 24, 2.0::NUMERIC),
        ('LG UltraGear 27GR75Q', 36, 48.0::NUMERIC),
        ('Acer Nitro VG240Y', 36, 30.0::NUMERIC),
        ('Cooler Master Notepal X150R', 12, 5.0::NUMERIC),
        ('DeepCool Multi Core X6', 12, 5.0::NUMERIC),
        ('Logitech C920 HD Pro', 24, 3.0::NUMERIC),
        ('HP 320 FHD Webcam', 12, 3.0::NUMERIC),
        ('HyperX SoloCast', 24, 4.0::NUMERIC),
        ('FIFINE K669B', 12, 4.0::NUMERIC)
) AS seed(name, warranty_months, power_watts)
  ON p.name = seed.name
ON CONFLICT (product_id) DO UPDATE
SET warranty_months = EXCLUDED.warranty_months,
    power_watts = EXCLUDED.power_watts;

INSERT INTO apparel (product_id, size, material)
SELECT p.product_id, seed.size, seed.material
FROM products p
JOIN (
    VALUES
        ('Nike Pegasus 40', '10', 'mesh'),
        ('Adidas Ultraboost Light', '10', 'mesh')
) AS seed(name, size, material)
  ON p.name = seed.name
ON CONFLICT (product_id) DO UPDATE
SET size = EXCLUDED.size,
    material = EXCLUDED.material;

INSERT INTO accessories (product_id, size, material)
SELECT p.product_id, seed.size, seed.material
FROM products p
JOIN (
    VALUES
        ('SteelSeries QcK Large', 'large', 'cloth and rubber'),
        ('Razer Gigantus V2 Medium', 'medium', 'cloth'),
        ('HyperX Wrist Rest Full Size', 'full-size', 'memory foam'),
        ('Razer Ergonomic Wrist Rest Pro', 'full-size', 'memory foam'),
        ('North Bayou F80 Monitor Arm', 'single', 'aluminium'),
        ('Amazon Basics Dual Monitor Arm', 'dual', 'steel'),
        ('Portronics My Buddy K Laptop Stand', 'universal', 'aluminium'),
        ('MOCA Adjustable Laptop Riser', 'universal', 'aluminium'),
        ('Amazon Basics Cable Management Sleeve', 'standard', 'neoprene'),
        ('Tizum Under Desk Headphone Hanger', 'standard', 'ABS plastic')
) AS seed(name, size, material)
  ON p.name = seed.name
ON CONFLICT (product_id) DO UPDATE
SET size = EXCLUDED.size,
    material = EXCLUDED.material;

INSERT INTO furniture (product_id, size, material)
SELECT p.product_id, seed.size, seed.material
FROM products p
JOIN (
    VALUES
        ('Green Soul Seoul Mid Back Chair', 'medium', 'mesh')
) AS seed(name, size, material)
  ON p.name = seed.name
ON CONFLICT (product_id) DO UPDATE
SET size = EXCLUDED.size,
    material = EXCLUDED.material;

WITH order_seed AS (
    SELECT *
    FROM (
        VALUES
            ('aarav_audio_focus', 'aarav@example.com', INTERVAL '14 days'),
            ('aarav_keyboard_setup', 'aarav@example.com', INTERVAL '18 hours'),
            ('aarav_mouse_setup', 'aarav@example.com', INTERVAL '4 days'),
            ('diya_keyboard_setup', 'diya@example.com', INTERVAL '20 hours'),
            ('diya_mouse_setup', 'diya@example.com', INTERVAL '6 days'),
            ('diya_laptop_setup', 'diya@example.com', INTERVAL '26 hours'),
            ('ishaan_monitor_setup', 'ishaan@example.com', INTERVAL '9 days'),
            ('ishaan_stream_setup', 'ishaan@example.com', INTERVAL '22 hours'),
            ('ishaan_mouse_setup', 'ishaan@example.com', INTERVAL '14 days'),
            ('meera_running_purchase', 'meera@example.com', INTERVAL '17 days'),
            ('meera_laptop_setup', 'meera@example.com', INTERVAL '3 days'),
            ('meera_headphone_setup', 'meera@example.com', INTERVAL '30 hours'),
            ('nisha_running_purchase', 'nisha@example.com', INTERVAL '35 days'),
            ('nisha_keyboard_setup', 'nisha@example.com', INTERVAL '10 days'),
            ('rohan_audio_setup', 'rohan@example.com', INTERVAL '80 days'),
            ('rohan_monitor_setup', 'rohan@example.com', INTERVAL '5 days'),
            ('sana_creator_setup', 'sana@example.com', INTERVAL '12 hours'),
            ('sana_keyboard_setup', 'sana@example.com', INTERVAL '2 days'),
            ('vivaan_smart_home', 'vivaan@example.com', INTERVAL '3 days'),
            ('vivaan_mouse_only', 'vivaan@example.com', INTERVAL '16 hours'),
            ('vivaan_creator_setup', 'vivaan@example.com', INTERVAL '7 days')
    ) AS t(order_key, email, offset_interval)
),
order_line_seed AS (
    SELECT *
    FROM (
        VALUES
            ('aarav_audio_focus', 'Sony WH-1000XM4', 1),
            ('aarav_keyboard_setup', 'Keychron K2', 1),
            ('aarav_keyboard_setup', 'HyperX Wrist Rest Full Size', 1),
            ('aarav_mouse_setup', 'Logitech G Pro X Superlight 2', 1),
            ('aarav_mouse_setup', 'SteelSeries QcK Large', 1),
            ('diya_keyboard_setup', 'Logitech MX Keys Mini', 1),
            ('diya_keyboard_setup', 'Razer Ergonomic Wrist Rest Pro', 1),
            ('diya_mouse_setup', 'Razer DeathAdder V3 Pro', 1),
            ('diya_mouse_setup', 'Razer Gigantus V2 Medium', 1),
            ('diya_laptop_setup', 'Portronics My Buddy K Laptop Stand', 1),
            ('diya_laptop_setup', 'DeepCool Multi Core X6', 1),
            ('ishaan_monitor_setup', 'LG UltraGear 27GR75Q', 1),
            ('ishaan_monitor_setup', 'North Bayou F80 Monitor Arm', 1),
            ('ishaan_monitor_setup', 'Amazon Basics Cable Management Sleeve', 1),
            ('ishaan_stream_setup', 'Logitech C920 HD Pro', 1),
            ('ishaan_stream_setup', 'HyperX SoloCast', 1),
            ('ishaan_mouse_setup', 'Logitech G Pro X Superlight 2', 1),
            ('ishaan_mouse_setup', 'SteelSeries QcK Large', 1),
            ('meera_running_purchase', 'Adidas Ultraboost Light', 1),
            ('meera_laptop_setup', 'MOCA Adjustable Laptop Riser', 1),
            ('meera_laptop_setup', 'Cooler Master Notepal X150R', 1),
            ('meera_headphone_setup', 'Apple AirPods Pro', 1),
            ('meera_headphone_setup', 'Tizum Under Desk Headphone Hanger', 1),
            ('nisha_running_purchase', 'Nike Pegasus 40', 1),
            ('nisha_keyboard_setup', 'Keychron K2', 1),
            ('nisha_keyboard_setup', 'HyperX Wrist Rest Full Size', 1),
            ('rohan_audio_setup', 'Bose QuietComfort 45', 1),
            ('rohan_audio_setup', 'Tizum Under Desk Headphone Hanger', 1),
            ('rohan_monitor_setup', 'Acer Nitro VG240Y', 1),
            ('rohan_monitor_setup', 'Amazon Basics Dual Monitor Arm', 1),
            ('sana_creator_setup', 'HP 320 FHD Webcam', 1),
            ('sana_creator_setup', 'FIFINE K669B', 1),
            ('sana_keyboard_setup', 'Logitech MX Keys Mini', 1),
            ('sana_keyboard_setup', 'HyperX Wrist Rest Full Size', 1),
            ('sana_keyboard_setup', 'Logitech G Pro X Superlight 2', 1),
            ('vivaan_smart_home', 'Google Nest Mini', 1),
            ('vivaan_mouse_only', 'Razer DeathAdder V3 Pro', 1),
            ('vivaan_creator_setup', 'Logitech C920 HD Pro', 1),
            ('vivaan_creator_setup', 'HyperX SoloCast', 1)
    ) AS t(order_key, product_name, quantity)
),
order_totals AS (
    SELECT
        os.order_key,
        os.email,
        os.offset_interval,
        SUM(p.price * ols.quantity)::NUMERIC(12, 2) AS total_amt
    FROM order_seed os
    JOIN order_line_seed ols ON ols.order_key = os.order_key
    JOIN products p ON p.name = ols.product_name
    GROUP BY os.order_key, os.email, os.offset_interval
)
INSERT INTO orders (user_id, total_amt, created_at)
SELECT
    u.user_id,
    ot.total_amt,
    CURRENT_TIMESTAMP - ot.offset_interval
FROM order_totals ot
JOIN users u ON u.email = ot.email
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.user_id = u.user_id
      AND o.total_amt = ot.total_amt
      AND o.created_at = CURRENT_TIMESTAMP - ot.offset_interval
);

WITH order_seed AS (
    SELECT *
    FROM (
        VALUES
            ('aarav_audio_focus', 'aarav@example.com', INTERVAL '14 days'),
            ('aarav_keyboard_setup', 'aarav@example.com', INTERVAL '18 hours'),
            ('aarav_mouse_setup', 'aarav@example.com', INTERVAL '4 days'),
            ('diya_keyboard_setup', 'diya@example.com', INTERVAL '20 hours'),
            ('diya_mouse_setup', 'diya@example.com', INTERVAL '6 days'),
            ('diya_laptop_setup', 'diya@example.com', INTERVAL '26 hours'),
            ('ishaan_monitor_setup', 'ishaan@example.com', INTERVAL '9 days'),
            ('ishaan_stream_setup', 'ishaan@example.com', INTERVAL '22 hours'),
            ('ishaan_mouse_setup', 'ishaan@example.com', INTERVAL '14 days'),
            ('meera_running_purchase', 'meera@example.com', INTERVAL '17 days'),
            ('meera_laptop_setup', 'meera@example.com', INTERVAL '3 days'),
            ('meera_headphone_setup', 'meera@example.com', INTERVAL '30 hours'),
            ('nisha_running_purchase', 'nisha@example.com', INTERVAL '35 days'),
            ('nisha_keyboard_setup', 'nisha@example.com', INTERVAL '10 days'),
            ('rohan_audio_setup', 'rohan@example.com', INTERVAL '80 days'),
            ('rohan_monitor_setup', 'rohan@example.com', INTERVAL '5 days'),
            ('sana_creator_setup', 'sana@example.com', INTERVAL '12 hours'),
            ('sana_keyboard_setup', 'sana@example.com', INTERVAL '2 days'),
            ('vivaan_smart_home', 'vivaan@example.com', INTERVAL '3 days'),
            ('vivaan_mouse_only', 'vivaan@example.com', INTERVAL '16 hours'),
            ('vivaan_creator_setup', 'vivaan@example.com', INTERVAL '7 days')
    ) AS t(order_key, email, offset_interval)
),
order_line_seed AS (
    SELECT *
    FROM (
        VALUES
            ('aarav_audio_focus', 'Sony WH-1000XM4', 1),
            ('aarav_keyboard_setup', 'Keychron K2', 1),
            ('aarav_keyboard_setup', 'HyperX Wrist Rest Full Size', 1),
            ('aarav_mouse_setup', 'Logitech G Pro X Superlight 2', 1),
            ('aarav_mouse_setup', 'SteelSeries QcK Large', 1),
            ('diya_keyboard_setup', 'Logitech MX Keys Mini', 1),
            ('diya_keyboard_setup', 'Razer Ergonomic Wrist Rest Pro', 1),
            ('diya_mouse_setup', 'Razer DeathAdder V3 Pro', 1),
            ('diya_mouse_setup', 'Razer Gigantus V2 Medium', 1),
            ('diya_laptop_setup', 'Portronics My Buddy K Laptop Stand', 1),
            ('diya_laptop_setup', 'DeepCool Multi Core X6', 1),
            ('ishaan_monitor_setup', 'LG UltraGear 27GR75Q', 1),
            ('ishaan_monitor_setup', 'North Bayou F80 Monitor Arm', 1),
            ('ishaan_monitor_setup', 'Amazon Basics Cable Management Sleeve', 1),
            ('ishaan_stream_setup', 'Logitech C920 HD Pro', 1),
            ('ishaan_stream_setup', 'HyperX SoloCast', 1),
            ('ishaan_mouse_setup', 'Logitech G Pro X Superlight 2', 1),
            ('ishaan_mouse_setup', 'SteelSeries QcK Large', 1),
            ('meera_running_purchase', 'Adidas Ultraboost Light', 1),
            ('meera_laptop_setup', 'MOCA Adjustable Laptop Riser', 1),
            ('meera_laptop_setup', 'Cooler Master Notepal X150R', 1),
            ('meera_headphone_setup', 'Apple AirPods Pro', 1),
            ('meera_headphone_setup', 'Tizum Under Desk Headphone Hanger', 1),
            ('nisha_running_purchase', 'Nike Pegasus 40', 1),
            ('nisha_keyboard_setup', 'Keychron K2', 1),
            ('nisha_keyboard_setup', 'HyperX Wrist Rest Full Size', 1),
            ('rohan_audio_setup', 'Bose QuietComfort 45', 1),
            ('rohan_audio_setup', 'Tizum Under Desk Headphone Hanger', 1),
            ('rohan_monitor_setup', 'Acer Nitro VG240Y', 1),
            ('rohan_monitor_setup', 'Amazon Basics Dual Monitor Arm', 1),
            ('sana_creator_setup', 'HP 320 FHD Webcam', 1),
            ('sana_creator_setup', 'FIFINE K669B', 1),
            ('sana_keyboard_setup', 'Logitech MX Keys Mini', 1),
            ('sana_keyboard_setup', 'HyperX Wrist Rest Full Size', 1),
            ('sana_keyboard_setup', 'Logitech G Pro X Superlight 2', 1),
            ('vivaan_smart_home', 'Google Nest Mini', 1),
            ('vivaan_mouse_only', 'Razer DeathAdder V3 Pro', 1),
            ('vivaan_creator_setup', 'Logitech C920 HD Pro', 1),
            ('vivaan_creator_setup', 'HyperX SoloCast', 1)
    ) AS t(order_key, product_name, quantity)
),
order_totals AS (
    SELECT
        os.order_key,
        os.email,
        os.offset_interval,
        SUM(p.price * ols.quantity)::NUMERIC(12, 2) AS total_amt
    FROM order_seed os
    JOIN order_line_seed ols ON ols.order_key = os.order_key
    JOIN products p ON p.name = ols.product_name
    GROUP BY os.order_key, os.email, os.offset_interval
),
seeded_orders AS (
    SELECT
        ot.order_key,
        o.order_id
    FROM order_totals ot
    JOIN users u ON u.email = ot.email
    JOIN orders o
      ON o.user_id = u.user_id
     AND o.total_amt = ot.total_amt
     AND o.created_at = CURRENT_TIMESTAMP - ot.offset_interval
)
INSERT INTO order_details (order_id, product_id, quantity, unit_price, category_id)
SELECT
    so.order_id,
    p.product_id,
    ols.quantity,
    p.price,
    p.category_id
FROM seeded_orders so
JOIN order_line_seed ols ON ols.order_key = so.order_key
JOIN products p ON p.name = ols.product_name
WHERE NOT EXISTS (
    SELECT 1
    FROM order_details od
    WHERE od.order_id = so.order_id
      AND od.product_id = p.product_id
);

SELECT fn_refresh_rfm_scores();
