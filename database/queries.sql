-- ============================================
-- Veel gebruikte queries voor dagelijks gebruik
-- ============================================

-- ============================================
-- VOORRAAD QUERIES
-- ============================================

-- 1. Alle artikelen met lage voorraad (herbevoorrading nodig)
SELECT
    product_code,
    product_name,
    total_available,
    total_reserved,
    minimum_stock,
    reorder_point,
    (reorder_point - total_available) as te_bestellen
FROM v_product_inventory
WHERE needs_reorder = true
ORDER BY total_available ASC;

-- 2. Voorraadwaarde per artikel
SELECT
    p.product_code,
    p.name,
    SUM(i.quantity_physical) as totale_voorraad,
    p.purchase_price as inkoopprijs,
    SUM(i.quantity_physical * p.purchase_price) as voorraadwaarde_inkoop,
    p.sales_price as verkoopprijs,
    SUM(i.quantity_physical * p.sales_price) as voorraadwaarde_verkoop
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
WHERE p.is_active = true
GROUP BY p.id, p.product_code, p.name, p.purchase_price, p.sales_price
HAVING SUM(i.quantity_physical) > 0
ORDER BY voorraadwaarde_inkoop DESC;

-- 3. Totale voorraadwaarde
SELECT
    SUM(i.quantity_physical * p.purchase_price) as totale_voorraadwaarde_inkoop,
    SUM(i.quantity_physical * p.sales_price) as totale_voorraadwaarde_verkoop,
    COUNT(DISTINCT p.id) as aantal_artikelen,
    SUM(i.quantity_physical) as totaal_stuks
FROM inventory i
JOIN products p ON i.product_id = p.id
WHERE i.quantity_physical > 0;

-- 4. Voorraad per locatie
SELECT
    wl.location_code,
    wl.warehouse,
    p.product_code,
    p.name,
    i.quantity_available,
    i.quantity_reserved,
    i.quantity_physical
FROM inventory i
JOIN products p ON i.product_id = p.id
JOIN warehouse_locations wl ON i.location_id = wl.id
WHERE i.quantity_physical > 0
ORDER BY wl.location_code, p.product_code;

-- 5. Voorraadmutaties laatste 30 dagen
SELECT
    it.transaction_number,
    it.transaction_date,
    it.transaction_type,
    p.product_code,
    p.name,
    it.quantity,
    wl_from.location_code as van_locatie,
    wl_to.location_code as naar_locatie,
    it.reference_type,
    it.notes
FROM inventory_transactions it
JOIN products p ON it.product_id = p.id
LEFT JOIN warehouse_locations wl_from ON it.from_location_id = wl_from.id
LEFT JOIN warehouse_locations wl_to ON it.to_location_id = wl_to.id
WHERE it.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY it.transaction_date DESC;

-- ============================================
-- INKOOP QUERIES
-- ============================================

-- 6. Openstaande inkooporders
SELECT * FROM v_open_purchase_orders
ORDER BY expected_delivery_date;

-- 7. Inkooporders deze maand
SELECT
    po.order_number,
    s.company_name as leverancier,
    po.order_date,
    po.expected_delivery_date,
    po.status,
    po.total_amount,
    COUNT(pol.id) as aantal_regels
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.id
LEFT JOIN purchase_order_lines pol ON po.id = pol.purchase_order_id
WHERE po.order_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY po.id, po.order_number, s.company_name, po.order_date,
         po.expected_delivery_date, po.status, po.total_amount
ORDER BY po.order_date DESC;

-- 8. Te ontvangen goederen (per artikel)
SELECT
    p.product_code,
    p.name,
    po.order_number,
    s.company_name as leverancier,
    pol.quantity,
    pol.quantity_received,
    pol.quantity_outstanding,
    po.expected_delivery_date
FROM purchase_order_lines pol
JOIN purchase_orders po ON pol.purchase_order_id = po.id
JOIN suppliers s ON po.supplier_id = s.id
JOIN products p ON pol.product_id = p.id
WHERE pol.quantity_outstanding > 0
  AND po.status NOT IN ('geannuleerd')
ORDER BY po.expected_delivery_date, p.product_code;

-- 9. Inkoop per leverancier (dit jaar)
SELECT
    s.supplier_code,
    s.company_name,
    COUNT(DISTINCT po.id) as aantal_orders,
    SUM(po.total_amount) as totaal_bedrag,
    AVG(po.total_amount) as gemiddelde_orderwaarde
FROM suppliers s
LEFT JOIN purchase_orders po ON s.id = po.supplier_id
WHERE po.order_date >= DATE_TRUNC('year', CURRENT_DATE)
  AND po.status != 'geannuleerd'
GROUP BY s.id, s.supplier_code, s.company_name
ORDER BY totaal_bedrag DESC;

-- ============================================
-- VERKOOP QUERIES
-- ============================================

-- 10. Openstaande verkooporders
SELECT * FROM v_open_sales_orders
ORDER BY requested_delivery_date;

-- 11. Verkooporders deze maand
SELECT
    so.order_number,
    c.company_name as klant,
    so.order_date,
    so.requested_delivery_date,
    so.status,
    so.total_amount,
    COUNT(sol.id) as aantal_regels
FROM sales_orders so
JOIN customers c ON so.customer_id = c.id
LEFT JOIN sales_order_lines sol ON so.id = sol.sales_order_id
WHERE so.order_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY so.id, so.order_number, c.company_name, so.order_date,
         so.requested_delivery_date, so.status, so.total_amount
ORDER BY so.order_date DESC;

-- 12. Te leveren goederen (per artikel)
SELECT
    p.product_code,
    p.name,
    so.order_number,
    c.company_name as klant,
    sol.quantity,
    sol.quantity_delivered,
    sol.quantity_outstanding,
    so.requested_delivery_date,
    -- Check voorraad beschikbaarheid
    COALESCE(inv.total_available, 0) as beschikbare_voorraad,
    CASE
        WHEN COALESCE(inv.total_available, 0) >= sol.quantity_outstanding THEN 'Op voorraad'
        WHEN COALESCE(inv.total_available, 0) > 0 THEN 'Deels beschikbaar'
        ELSE 'Niet op voorraad'
    END as voorraad_status
FROM sales_order_lines sol
JOIN sales_orders so ON sol.sales_order_id = so.id
JOIN customers c ON so.customer_id = c.id
JOIN products p ON sol.product_id = p.id
LEFT JOIN v_product_inventory inv ON p.id = inv.product_id
WHERE sol.quantity_outstanding > 0
  AND so.status NOT IN ('geannuleerd', 'geleverd')
ORDER BY so.requested_delivery_date, p.product_code;

-- 13. Omzet per klant (dit jaar)
SELECT
    c.customer_code,
    c.company_name,
    COUNT(DISTINCT so.id) as aantal_orders,
    SUM(so.total_amount) as totale_omzet,
    AVG(so.total_amount) as gemiddelde_orderwaarde,
    c.credit_limit,
    (c.credit_limit - COALESCE(SUM(so.total_amount), 0)) as resterend_krediet
FROM customers c
LEFT JOIN sales_orders so ON c.id = so.customer_id
WHERE so.order_date >= DATE_TRUNC('year', CURRENT_DATE)
  AND so.status NOT IN ('geannuleerd')
GROUP BY c.id, c.customer_code, c.company_name, c.credit_limit
ORDER BY totale_omzet DESC;

-- 14. Top 10 best verkochte producten (dit jaar)
SELECT
    p.product_code,
    p.name,
    p.category,
    SUM(sol.quantity_delivered) as totaal_verkocht,
    SUM(sol.line_total) as totale_omzet,
    COUNT(DISTINCT sol.sales_order_id) as aantal_orders
FROM sales_order_lines sol
JOIN sales_orders so ON sol.sales_order_id = so.id
JOIN products p ON sol.product_id = p.id
WHERE so.order_date >= DATE_TRUNC('year', CURRENT_DATE)
  AND so.status NOT IN ('geannuleerd')
GROUP BY p.id, p.product_code, p.name, p.category
ORDER BY totaal_verkocht DESC
LIMIT 10;

-- ============================================
-- RAPPORTAGES
-- ============================================

-- 15. Omzet per maand (dit jaar)
SELECT
    TO_CHAR(so.order_date, 'YYYY-MM') as maand,
    COUNT(DISTINCT so.id) as aantal_orders,
    SUM(so.subtotal) as subtotaal,
    SUM(so.vat_amount) as btw,
    SUM(so.total_amount) as totaal_incl_btw
FROM sales_orders so
WHERE so.order_date >= DATE_TRUNC('year', CURRENT_DATE)
  AND so.status NOT IN ('geannuleerd')
GROUP BY TO_CHAR(so.order_date, 'YYYY-MM')
ORDER BY maand;

-- 16. Marge analyse per product
SELECT
    p.product_code,
    p.name,
    p.purchase_price as inkoopprijs,
    p.sales_price as verkoopprijs,
    (p.sales_price - p.purchase_price) as marge_per_stuk,
    ROUND(((p.sales_price - p.purchase_price) / NULLIF(p.sales_price, 0) * 100)::numeric, 2) as marge_percentage,
    COALESCE(SUM(sol.quantity_delivered), 0) as verkocht_aantal,
    COALESCE(SUM(sol.quantity_delivered * (p.sales_price - p.purchase_price)), 0) as totale_marge
FROM products p
LEFT JOIN sales_order_lines sol ON p.id = sol.product_id
LEFT JOIN sales_orders so ON sol.sales_order_id = so.id
    AND so.order_date >= DATE_TRUNC('year', CURRENT_DATE)
    AND so.status NOT IN ('geannuleerd')
WHERE p.is_active = true
GROUP BY p.id, p.product_code, p.name, p.purchase_price, p.sales_price
ORDER BY totale_marge DESC;

-- 17. Leveranciers prestatie
SELECT
    s.supplier_code,
    s.company_name,
    COUNT(po.id) as totaal_orders,
    COUNT(CASE WHEN po.actual_delivery_date <= po.expected_delivery_date THEN 1 END) as op_tijd_geleverd,
    COUNT(CASE WHEN po.actual_delivery_date > po.expected_delivery_date THEN 1 END) as te_laat,
    ROUND((COUNT(CASE WHEN po.actual_delivery_date <= po.expected_delivery_date THEN 1 END)::numeric /
           NULLIF(COUNT(CASE WHEN po.actual_delivery_date IS NOT NULL THEN 1 END), 0) * 100), 2) as op_tijd_percentage,
    AVG(po.total_amount) as gemiddelde_orderwaarde
FROM suppliers s
LEFT JOIN purchase_orders po ON s.id = po.supplier_id
WHERE po.order_date >= DATE_TRUNC('year', CURRENT_DATE)
GROUP BY s.id, s.supplier_code, s.company_name
ORDER BY op_tijd_percentage DESC;

-- 18. Voorraad omloopsnelheid (inventory turnover)
SELECT
    p.product_code,
    p.name,
    p.category,
    COALESCE(inv.total_physical, 0) as huidige_voorraad,
    COALESCE(SUM(ABS(it.quantity)), 0) as totaal_verkocht_dit_jaar,
    CASE
        WHEN COALESCE(inv.total_physical, 0) > 0 THEN
            ROUND((COALESCE(SUM(ABS(it.quantity)), 0)::numeric / inv.total_physical), 2)
        ELSE 0
    END as omloopsnelheid
FROM products p
LEFT JOIN v_product_inventory inv ON p.id = inv.product_id
LEFT JOIN inventory_transactions it ON p.id = it.product_id
    AND it.transaction_type = 'verkoop'
    AND it.transaction_date >= DATE_TRUNC('year', CURRENT_DATE)
WHERE p.is_active = true
GROUP BY p.id, p.product_code, p.name, p.category, inv.total_physical
HAVING COALESCE(inv.total_physical, 0) > 0
ORDER BY omloopsnelheid DESC;

-- ============================================
-- DASHBOARD QUERIES
-- ============================================

-- 19. Dashboard samenvatting
SELECT
    'Totale voorraadwaarde' as metric,
    TO_CHAR(SUM(i.quantity_physical * p.purchase_price), 'FM€999,999,990.00') as waarde
FROM inventory i
JOIN products p ON i.product_id = p.id
UNION ALL
SELECT
    'Artikelen die herbevoorrading nodig hebben',
    COUNT(*)::text
FROM v_product_inventory
WHERE needs_reorder = true
UNION ALL
SELECT
    'Openstaande inkooporders',
    COUNT(*)::text
FROM v_open_purchase_orders
UNION ALL
SELECT
    'Openstaande verkooporders',
    COUNT(*)::text
FROM v_open_sales_orders
UNION ALL
SELECT
    'Omzet deze maand',
    TO_CHAR(COALESCE(SUM(total_amount), 0), 'FM€999,999,990.00')
FROM sales_orders
WHERE order_date >= DATE_TRUNC('month', CURRENT_DATE)
  AND status NOT IN ('geannuleerd')
UNION ALL
SELECT
    'Aantal klanten',
    COUNT(*)::text
FROM customers
WHERE is_active = true
UNION ALL
SELECT
    'Aantal leveranciers',
    COUNT(*)::text
FROM suppliers
WHERE is_active = true
UNION ALL
SELECT
    'Totaal aantal producten',
    COUNT(*)::text
FROM products
WHERE is_active = true;

-- 20. Laatste activiteiten
SELECT
    'Voorraadmutatie' as activiteit_type,
    it.transaction_number as referentie,
    p.name as beschrijving,
    it.transaction_date as datum,
    u.username as gebruiker
FROM inventory_transactions it
JOIN products p ON it.product_id = p.id
LEFT JOIN users u ON it.created_by = u.id
WHERE it.transaction_date >= CURRENT_DATE - INTERVAL '7 days'

UNION ALL

SELECT
    'Inkooporder' as activiteit_type,
    po.order_number as referentie,
    s.company_name as beschrijving,
    po.created_at as datum,
    u.username as gebruiker
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.id
LEFT JOIN users u ON po.created_by = u.id
WHERE po.created_at >= CURRENT_DATE - INTERVAL '7 days'

UNION ALL

SELECT
    'Verkooporder' as activiteit_type,
    so.order_number as referentie,
    c.company_name as beschrijving,
    so.created_at as datum,
    u.username as gebruiker
FROM sales_orders so
JOIN customers c ON so.customer_id = c.id
LEFT JOIN users u ON so.created_by = u.id
WHERE so.created_at >= CURRENT_DATE - INTERVAL '7 days'

ORDER BY datum DESC
LIMIT 20;
