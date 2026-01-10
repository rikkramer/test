-- ============================================
-- Demo/Test Data voor Inkoop/Verkoop Systeem
-- ============================================

-- ============================================
-- GEBRUIKERS
-- ============================================
INSERT INTO users (username, email, password_hash, first_name, last_name) VALUES
('admin', 'admin@bedrijf.nl', '$2a$10$demoHashVoorTesten', 'Admin', 'Beheerder'),
('demo', 'demo@bedrijf.nl', '$2a$10$demoHashVoorTesten', 'Demo', 'Gebruiker'),
('inkoper', 'inkoper@bedrijf.nl', '$2a$10$demoHashVoorTesten', 'Jan', 'Inkoper'),
('verkoper', 'verkoper@bedrijf.nl', '$2a$10$demoHashVoorTesten', 'Marie', 'Verkoper');

-- ============================================
-- LEVERANCIERS
-- ============================================
INSERT INTO suppliers (supplier_code, company_name, contact_person, email, phone, address, postal_code, city, vat_number, payment_terms_days) VALUES
('LEV001', 'TechParts BV', 'Hans de Vries', 'info@techparts.nl', '020-1234567', 'Industrieweg 10', '1234 AB', 'Amsterdam', 'NL123456789B01', 30),
('LEV002', 'Kantoor Totaal', 'Sophie Jansen', 'verkoop@kantoortotaal.nl', '030-9876543', 'Papierstraat 5', '3500 CD', 'Utrecht', 'NL987654321B02', 14),
('LEV003', 'Electronics Wholesale', 'Peter Berg', 'p.berg@electronics.nl', '010-5555666', 'Elektronicaweg 22', '3011 EF', 'Rotterdam', 'NL555666777B01', 30),
('LEV004', 'Meubelmakerij de Jong', 'Lisa de Jong', 'info@meubeldejong.nl', '040-3334444', 'Houtstraat 15', '5600 GH', 'Eindhoven', 'NL333444555B03', 21);

-- ============================================
-- KLANTEN
-- ============================================
INSERT INTO customers (customer_code, company_name, contact_person, email, phone,
                      invoice_address, invoice_postal_code, invoice_city,
                      delivery_address, delivery_postal_code, delivery_city,
                      vat_number, payment_terms_days, credit_limit) VALUES
('KL001', 'Retail Solutions BV', 'Tom Bakker', 'tom@retailsolutions.nl', '020-1112222',
 'Winkelstraat 100', '1000 AA', 'Amsterdam',
 'Winkelstraat 100', '1000 AA', 'Amsterdam',
 'NL111222333B01', 30, 50000.00),

('KL002', 'Webshop Express', 'Emma Visser', 'emma@webshopexpress.nl', '030-3334444',
 'Pakketweg 25', '3500 BB', 'Utrecht',
 'Distributiecentrum 1', '3500 ZZ', 'Utrecht',
 'NL444555666B02', 14, 75000.00),

('KL003', 'Office Supplies NL', 'Mark de Wit', 'mark@officesupplies.nl', '070-7778899',
 'Kantoorlaan 50', '2500 CC', 'Den Haag',
 'Kantoorlaan 50', '2500 CC', 'Den Haag',
 'NL777888999B03', 30, 25000.00),

('KL004', 'Tech Retail Group', 'Sandra Koster', 's.koster@techretail.nl', '010-9990000',
 'Hoofdkantoor 1', '3000 DD', 'Rotterdam',
 'Magazijn Zuidplein 10', '3083 AB', 'Rotterdam',
 'NL999000111B04', 21, 100000.00);

-- ============================================
-- MAGAZIJNLOCATIES
-- ============================================
INSERT INTO warehouse_locations (location_code, warehouse, aisle, rack, shelf, bin) VALUES
-- Hoofdmagazijn
('A-01-01-01', 'Hoofdmagazijn', 'A', '01', '01', '01'),
('A-01-01-02', 'Hoofdmagazijn', 'A', '01', '01', '02'),
('A-01-02-01', 'Hoofdmagazijn', 'A', '01', '02', '01'),
('A-02-01-01', 'Hoofdmagazijn', 'A', '02', '01', '01'),
('B-01-01-01', 'Hoofdmagazijn', 'B', '01', '01', '01'),
('B-01-02-01', 'Hoofdmagazijn', 'B', '01', '02', '01'),
('B-02-01-01', 'Hoofdmagazijn', 'B', '02', '01', '01'),

-- Koelmagazijn
('C-01-01-01', 'Koelmagazijn', 'C', '01', '01', '01'),
('C-01-02-01', 'Koelmagazijn', 'C', '01', '02', '01'),

-- Retourlocatie
('RET-01', 'Retouren', NULL, NULL, NULL, '01'),
('QUAR-01', 'Quarantaine', NULL, NULL, NULL, '01');

-- ============================================
-- PRODUCTEN / ARTIKELSTAM
-- ============================================
INSERT INTO products (product_code, ean_code, name, description, category, unit,
                     purchase_price, sales_price, vat_rate,
                     minimum_stock, maximum_stock, reorder_point,
                     default_supplier_id, is_active, is_purchasable, is_sellable)
SELECT
    'ART001', '8712345678901', 'Laptop Dell Latitude 5420', '14 inch business laptop, i5, 16GB RAM, 512GB SSD', 'Computers', 'stuks',
    750.00, 999.00, 21.00,
    5, 20, 8,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV001'
UNION ALL
SELECT
    'ART002', '8712345678902', 'USB-C Hub 7-poorts', 'Universele USB-C hub met HDMI, USB 3.0 en ethernet', 'Accessoires', 'stuks',
    25.00, 49.95, 21.00,
    20, 100, 30,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV003'
UNION ALL
SELECT
    'ART003', '8712345678903', 'Bureaulamp LED', 'Instelbare LED bureaulamp met USB lader', 'Kantoorartikelen', 'stuks',
    15.00, 29.95, 21.00,
    10, 50, 15,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV002'
UNION ALL
SELECT
    'ART004', '8712345678904', 'Bureaustoelen ErgoMax', 'Ergonomische bureaustoel met lendensteun', 'Meubilair', 'stuks',
    180.00, 349.00, 21.00,
    3, 15, 5,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV004'
UNION ALL
SELECT
    'ART005', '8712345678905', 'Monitor 27" 4K', '27 inch 4K IPS monitor met USB-C', 'Computers', 'stuks',
    320.00, 549.00, 21.00,
    8, 25, 10,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV003'
UNION ALL
SELECT
    'ART006', '8712345678906', 'Draadloos toetsenbord + muis', 'Stille draadloze toetsenbord en muis set', 'Accessoires', 'stuks',
    35.00, 69.95, 21.00,
    15, 60, 20,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV003'
UNION ALL
SELECT
    'ART007', '8712345678907', 'A4 Printerpapier 500 vel', 'Wit kopieerpapier 80g/m² - Doos 5 pakken', 'Kantoorartikelen', 'doos',
    18.50, 32.95, 21.00,
    50, 200, 75,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV002'
UNION ALL
SELECT
    'ART008', '8712345678908', 'Webcam Full HD', '1080p webcam met microfoon en privacy cover', 'Accessoires', 'stuks',
    45.00, 79.95, 21.00,
    12, 40, 18,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV003'
UNION ALL
SELECT
    'ART009', '8712345678909', 'Verstelbaar bureau 160x80', 'Elektrisch verstelbaar bureau, hoogte 65-125cm', 'Meubilair', 'stuks',
    420.00, 749.00, 21.00,
    2, 10, 4,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV004'
UNION ALL
SELECT
    'ART010', '8712345678910', 'Netwerkkabel CAT6 5m', 'UTP netwerkkabel 5 meter blauw', 'Accessoires', 'stuks',
    3.50, 8.95, 21.00,
    100, 500, 150,
    s.id, true, true, true
FROM suppliers s WHERE s.supplier_code = 'LEV003';

-- ============================================
-- VOORRAAD - Beginvoorraad
-- ============================================
INSERT INTO inventory (product_id, location_id, quantity_available, quantity_reserved)
SELECT
    p.id,
    wl.id,
    CASE
        WHEN p.product_code = 'ART001' THEN 12
        WHEN p.product_code = 'ART002' THEN 45
        WHEN p.product_code = 'ART003' THEN 23
        WHEN p.product_code = 'ART004' THEN 8
        WHEN p.product_code = 'ART005' THEN 15
        WHEN p.product_code = 'ART006' THEN 32
        WHEN p.product_code = 'ART007' THEN 120
        WHEN p.product_code = 'ART008' THEN 18
        WHEN p.product_code = 'ART009' THEN 5
        WHEN p.product_code = 'ART010' THEN 200
    END as quantity_available,
    0 as quantity_reserved
FROM products p
CROSS JOIN warehouse_locations wl
WHERE wl.location_code = 'A-01-01-01'
  AND p.product_code IN ('ART001', 'ART002', 'ART003', 'ART004', 'ART005',
                         'ART006', 'ART007', 'ART008', 'ART009', 'ART010');

-- ============================================
-- INKOOPORDERS
-- ============================================

-- Inkooporder 1 - Geleverd
INSERT INTO purchase_orders (order_number, supplier_id, order_date, expected_delivery_date,
                             actual_delivery_date, status, subtotal, vat_amount, total_amount,
                             created_by)
SELECT
    'PO-2026-001',
    s.id,
    '2025-12-15',
    '2025-12-22',
    '2025-12-21',
    'geleverd',
    7500.00,
    1575.00,
    9075.00,
    u.id
FROM suppliers s
CROSS JOIN users u
WHERE s.supplier_code = 'LEV001'
  AND u.username = 'inkoper';

-- Inkooporder regels voor PO-2026-001
INSERT INTO purchase_order_lines (purchase_order_id, line_number, product_id, quantity, quantity_received, unit_price)
SELECT
    po.id,
    1,
    p.id,
    10,
    10,
    750.00
FROM purchase_orders po
CROSS JOIN products p
WHERE po.order_number = 'PO-2026-001'
  AND p.product_code = 'ART001';

-- Inkooporder 2 - Besteld (nog niet geleverd)
INSERT INTO purchase_orders (order_number, supplier_id, order_date, expected_delivery_date,
                             status, subtotal, vat_amount, total_amount, created_by)
SELECT
    'PO-2026-002',
    s.id,
    '2026-01-05',
    '2026-01-15',
    'besteld',
    3250.00,
    682.50,
    3932.50,
    u.id
FROM suppliers s
CROSS JOIN users u
WHERE s.supplier_code = 'LEV003'
  AND u.username = 'inkoper';

-- Inkooporder regels voor PO-2026-002
INSERT INTO purchase_order_lines (purchase_order_id, line_number, product_id, quantity, quantity_received, unit_price)
SELECT
    po.id,
    1,
    p.id,
    50,
    0,
    25.00
FROM purchase_orders po
CROSS JOIN products p
WHERE po.order_number = 'PO-2026-002'
  AND p.product_code = 'ART002'
UNION ALL
SELECT
    po.id,
    2,
    p.id,
    20,
    0,
    45.00
FROM purchase_orders po
CROSS JOIN products p
WHERE po.order_number = 'PO-2026-002'
  AND p.product_code = 'ART008';

-- ============================================
-- VERKOOPORDERS
-- ============================================

-- Verkooporder 1 - Bevestigd
INSERT INTO sales_orders (order_number, customer_id, order_date, requested_delivery_date,
                         status, subtotal, vat_amount, total_amount,
                         delivery_address, delivery_postal_code, delivery_city,
                         created_by)
SELECT
    'SO-2026-001',
    c.id,
    '2026-01-08',
    '2026-01-12',
    'bevestigd',
    4494.50,
    943.85,
    5438.35,
    'Winkelstraat 100',
    '1000 AA',
    'Amsterdam',
    u.id
FROM customers c
CROSS JOIN users u
WHERE c.customer_code = 'KL001'
  AND u.username = 'verkoper';

-- Verkooporder regels voor SO-2026-001
INSERT INTO sales_order_lines (sales_order_id, line_number, product_id, quantity, quantity_delivered, unit_price, discount_percentage)
SELECT
    so.id,
    1,
    p.id,
    3,
    0,
    999.00,
    5.00  -- 5% korting
FROM sales_orders so
CROSS JOIN products p
WHERE so.order_number = 'SO-2026-001'
  AND p.product_code = 'ART001'
UNION ALL
SELECT
    so.id,
    2,
    p.id,
    10,
    0,
    49.95,
    0.00
FROM sales_orders so
CROSS JOIN products p
WHERE so.order_number = 'SO-2026-001'
  AND p.product_code = 'ART002'
UNION ALL
SELECT
    so.id,
    3,
    p.id,
    5,
    0,
    549.00,
    0.00
FROM sales_orders so
CROSS JOIN products p
WHERE so.order_number = 'SO-2026-001'
  AND p.product_code = 'ART005';

-- Verkooporder 2 - Deels geleverd
INSERT INTO sales_orders (order_number, customer_id, order_date, requested_delivery_date,
                         status, subtotal, vat_amount, total_amount,
                         delivery_address, delivery_postal_code, delivery_city,
                         created_by)
SELECT
    'SO-2026-002',
    c.id,
    '2026-01-06',
    '2026-01-10',
    'deels_geleverd',
    2498.00,
    524.58,
    3022.58,
    'Distributiecentrum 1',
    '3500 ZZ',
    'Utrecht',
    u.id
FROM customers c
CROSS JOIN users u
WHERE c.customer_code = 'KL002'
  AND u.username = 'verkoper';

-- Verkooporder regels voor SO-2026-002
INSERT INTO sales_order_lines (sales_order_id, line_number, product_id, quantity, quantity_delivered, unit_price)
SELECT
    so.id,
    1,
    p.id,
    20,
    15,  -- Deels geleverd
    69.95
FROM sales_orders so
CROSS JOIN products p
WHERE so.order_number = 'SO-2026-002'
  AND p.product_code = 'ART006'
UNION ALL
SELECT
    so.id,
    2,
    p.id,
    10,
    10,  -- Volledig geleverd
    79.95
FROM sales_orders so
CROSS JOIN products p
WHERE so.order_number = 'SO-2026-002'
  AND p.product_code = 'ART008';

-- ============================================
-- VOORRAADMUTATIES
-- ============================================

-- Inkomende voorraad van PO-2026-001
INSERT INTO inventory_transactions (transaction_number, transaction_date, transaction_type,
                                   product_id, to_location_id, quantity,
                                   reference_type, reference_id, unit_cost, created_by)
SELECT
    'IT-2025-001',
    '2025-12-21 10:30:00',
    'inkoop',
    p.id,
    wl.id,
    10,
    'purchase_order',
    po.id,
    750.00,
    u.id
FROM products p
CROSS JOIN warehouse_locations wl
CROSS JOIN purchase_orders po
CROSS JOIN users u
WHERE p.product_code = 'ART001'
  AND wl.location_code = 'A-01-01-01'
  AND po.order_number = 'PO-2026-001'
  AND u.username = 'inkoper';

-- Uitgaande voorraad voor SO-2026-002 (deels)
INSERT INTO inventory_transactions (transaction_number, transaction_date, transaction_type,
                                   product_id, from_location_id, quantity,
                                   reference_type, reference_id, unit_cost, created_by)
SELECT
    'IT-2026-001',
    '2026-01-07 14:15:00',
    'verkoop',
    p.id,
    wl.id,
    -15,  -- Negatief = uitgaand
    'sales_order',
    so.id,
    35.00,
    u.id
FROM products p
CROSS JOIN warehouse_locations wl
CROSS JOIN sales_orders so
CROSS JOIN users u
WHERE p.product_code = 'ART006'
  AND wl.location_code = 'A-01-01-01'
  AND so.order_number = 'SO-2026-002'
  AND u.username = 'verkoper';

INSERT INTO inventory_transactions (transaction_number, transaction_date, transaction_type,
                                   product_id, from_location_id, quantity,
                                   reference_type, reference_id, unit_cost, created_by)
SELECT
    'IT-2026-002',
    '2026-01-07 14:20:00',
    'verkoop',
    p.id,
    wl.id,
    -10,  -- Negatief = uitgaand
    'sales_order',
    so.id,
    45.00,
    u.id
FROM products p
CROSS JOIN warehouse_locations wl
CROSS JOIN sales_orders so
CROSS JOIN users u
WHERE p.product_code = 'ART008'
  AND wl.location_code = 'A-01-01-01'
  AND so.order_number = 'SO-2026-002'
  AND u.username = 'verkoper';

-- Voorraadcorrectie
INSERT INTO inventory_transactions (transaction_number, transaction_date, transaction_type,
                                   product_id, to_location_id, quantity,
                                   reference_type, unit_cost, notes, created_by)
SELECT
    'IT-2026-003',
    '2026-01-09 09:00:00',
    'correctie',
    p.id,
    wl.id,
    2,
    'tellijst',
    3.50,
    'Correctie na inventarisatie - 2 stuks gevonden',
    u.id
FROM products p
CROSS JOIN warehouse_locations wl
CROSS JOIN users u
WHERE p.product_code = 'ART010'
  AND wl.location_code = 'A-01-01-01'
  AND u.username = 'admin';
