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

INSERT INTO category_complements (source_category_id, target_category_id, complement_score) VALUES
    (5, 12, 0.9000),  -- Keyboards -> Wrist Rests
    (12, 5, 0.6500),  -- Wrist Rests -> Keyboards
    (10, 11, 0.9400), -- Mice -> Mouse Pads
    (11, 10, 0.7200), -- Mouse Pads -> Mice
    (14, 15, 0.9000), -- Monitors -> Monitor Arms
    (15, 14, 0.7600), -- Monitor Arms -> Monitors
    (17, 18, 0.7800), -- Laptop Stands -> Cooling Pads
    (18, 17, 0.7000), -- Cooling Pads -> Laptop Stands
    (24, 17, 0.7600), -- Laptops -> Laptop Stands
    (17, 24, 0.6500), -- Laptop Stands -> Laptops
    (24, 18, 0.8400), -- Laptops -> Cooling Pads
    (18, 24, 0.7000), -- Cooling Pads -> Laptops
    (36, 37, 0.7200), -- Webcams -> Microphones
    (37, 36, 0.6600), -- Microphones -> Webcams
    (3, 42, 0.5800),  -- Headphones -> Headphone Hangers
    (42, 3, 0.5200),  -- Headphone Hangers -> Headphones
    (14, 41, 0.5200), -- Monitors -> Cable Management
    (15, 41, 0.5600), -- Monitor Arms -> Cable Management
    (17, 41, 0.4600), -- Laptop Stands -> Cable Management
    (24, 41, 0.4200), -- Laptops -> Cable Management
    (5, 10, 0.6200),  -- Keyboards -> Mice
    (10, 5, 0.6000),  -- Mice -> Keyboards
    (19, 20, 0.9500), -- Printers -> Ink Bottles
    (20, 19, 0.6200), -- Ink Bottles -> Printers
    (21, 22, 0.9200), -- Smartphones -> Screen Protectors
    (22, 21, 0.6500), -- Screen Protectors -> Smartphones
    (21, 23, 0.9000), -- Smartphones -> Phone Cases
    (23, 21, 0.6700), -- Phone Cases -> Smartphones
    (7, 30, 0.8600),  -- Footwear -> Socks
    (30, 7, 0.5400),  -- Socks -> Footwear
    (31, 32, 0.9300), -- Toothpaste -> Toothbrushes
    (32, 31, 0.8900), -- Toothbrushes -> Toothpaste
    (31, 33, 0.6100), -- Toothpaste -> Mouthwash
    (33, 31, 0.6400), -- Mouthwash -> Toothpaste
    (31, 34, 0.5200), -- Toothpaste -> Dental Floss
    (34, 31, 0.5600), -- Dental Floss -> Toothpaste
    (32, 33, 0.4700), -- Toothbrushes -> Mouthwash
    (33, 32, 0.4300)  -- Mouthwash -> Toothbrushes
ON CONFLICT (source_category_id, target_category_id) DO UPDATE
SET complement_score = EXCLUDED.complement_score;
