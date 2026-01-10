-- ============================================
-- PostgreSQL Database Schema
-- Inkoop/Verkoop en Voorraadbeheer Systeem
-- ============================================

-- Maak extensions aan
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- GEBRUIKERS TABEL
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- ============================================
-- LEVERANCIERS
-- ============================================
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_code VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(255),
    postal_code VARCHAR(10),
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Nederland',
    vat_number VARCHAR(50),
    payment_terms_days INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- KLANTEN
-- ============================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),

    -- Factuuradres
    invoice_address VARCHAR(255),
    invoice_postal_code VARCHAR(10),
    invoice_city VARCHAR(100),
    invoice_country VARCHAR(100) DEFAULT 'Nederland',

    -- Leveradres
    delivery_address VARCHAR(255),
    delivery_postal_code VARCHAR(10),
    delivery_city VARCHAR(100),
    delivery_country VARCHAR(100) DEFAULT 'Nederland',

    vat_number VARCHAR(50),
    payment_terms_days INTEGER DEFAULT 30,
    credit_limit DECIMAL(15,2),
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ARTIKELSTAM (PRODUCTEN)
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    ean_code VARCHAR(13),
    sku VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),

    -- Eenheden
    unit VARCHAR(20) DEFAULT 'stuks', -- stuks, kg, liter, meter, etc.

    -- Prijzen
    purchase_price DECIMAL(15,2) DEFAULT 0.00,
    sales_price DECIMAL(15,2) DEFAULT 0.00,
    vat_rate DECIMAL(5,2) DEFAULT 21.00, -- BTW percentage

    -- Voorraad niveaus
    minimum_stock INTEGER DEFAULT 0,
    maximum_stock INTEGER DEFAULT 0,
    reorder_point INTEGER DEFAULT 0,

    -- Leverancier
    default_supplier_id UUID REFERENCES suppliers(id),

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_purchasable BOOLEAN DEFAULT true,
    is_sellable BOOLEAN DEFAULT true,

    -- Afmetingen/gewicht
    weight_kg DECIMAL(10,3),
    length_cm DECIMAL(10,2),
    width_cm DECIMAL(10,2),
    height_cm DECIMAL(10,2),

    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- MAGAZIJNLOCATIES
-- ============================================
CREATE TABLE warehouse_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_code VARCHAR(20) UNIQUE NOT NULL,
    warehouse VARCHAR(100) NOT NULL,
    aisle VARCHAR(10), -- Gang
    rack VARCHAR(10), -- Rek
    shelf VARCHAR(10), -- Plank
    bin VARCHAR(10), -- Vak
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INKOOPORDERS
-- ============================================
CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,

    -- Status
    status VARCHAR(20) DEFAULT 'concept', -- concept, besteld, deels_geleverd, geleverd, geannuleerd

    -- Totalen
    subtotal DECIMAL(15,2) DEFAULT 0.00,
    vat_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) DEFAULT 0.00,

    -- Leveradres
    delivery_address VARCHAR(255),
    delivery_postal_code VARCHAR(10),
    delivery_city VARCHAR(100),

    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INKOOPORDER REGELS
-- ============================================
CREATE TABLE purchase_order_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id),

    -- Hoeveelheden
    quantity INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    quantity_outstanding INTEGER GENERATED ALWAYS AS (quantity - quantity_received) STORED,

    -- Prijzen
    unit_price DECIMAL(15,2) NOT NULL,
    vat_rate DECIMAL(5,2) DEFAULT 21.00,
    line_total DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,

    expected_delivery_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(purchase_order_id, line_number)
);

-- ============================================
-- VERKOOPORDERS
-- ============================================
CREATE TABLE sales_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    requested_delivery_date DATE,
    actual_delivery_date DATE,

    -- Status
    status VARCHAR(20) DEFAULT 'concept', -- concept, bevestigd, deels_geleverd, geleverd, gefactureerd, geannuleerd

    -- Totalen
    subtotal DECIMAL(15,2) DEFAULT 0.00,
    vat_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) DEFAULT 0.00,

    -- Leveradres
    delivery_address VARCHAR(255),
    delivery_postal_code VARCHAR(10),
    delivery_city VARCHAR(100),

    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- VERKOOPORDER REGELS
-- ============================================
CREATE TABLE sales_order_lines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sales_order_id UUID NOT NULL REFERENCES sales_orders(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id),

    -- Hoeveelheden
    quantity INTEGER NOT NULL,
    quantity_delivered INTEGER DEFAULT 0,
    quantity_outstanding INTEGER GENERATED ALWAYS AS (quantity - quantity_delivered) STORED,

    -- Prijzen
    unit_price DECIMAL(15,2) NOT NULL,
    discount_percentage DECIMAL(5,2) DEFAULT 0.00,
    vat_rate DECIMAL(5,2) DEFAULT 21.00,
    line_total DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount_percentage / 100)) STORED,

    requested_delivery_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(sales_order_id, line_number)
);

-- ============================================
-- VOORRAAD
-- ============================================
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id),
    location_id UUID NOT NULL REFERENCES warehouse_locations(id),

    -- Hoeveelheden
    quantity_available INTEGER DEFAULT 0,
    quantity_reserved INTEGER DEFAULT 0,
    quantity_on_order INTEGER DEFAULT 0,
    quantity_physical INTEGER GENERATED ALWAYS AS (quantity_available + quantity_reserved) STORED,

    last_counted_date DATE,
    last_counted_quantity INTEGER,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(product_id, location_id)
);

-- ============================================
-- VOORRAADMUTATIES (TRANSACTIES)
-- ============================================
CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_number VARCHAR(50) UNIQUE NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Type mutatie
    transaction_type VARCHAR(20) NOT NULL, -- inkoop, verkoop, correctie, verplaatsing, retour

    product_id UUID NOT NULL REFERENCES products(id),
    from_location_id UUID REFERENCES warehouse_locations(id),
    to_location_id UUID REFERENCES warehouse_locations(id),

    -- Hoeveelheid (positief = toename, negatief = afname)
    quantity INTEGER NOT NULL,

    -- Referenties
    reference_type VARCHAR(50), -- purchase_order, sales_order, etc.
    reference_id UUID,

    unit_cost DECIMAL(15,2),

    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- VIEWS VOOR OVERZICHTEN
-- ============================================

-- View: Actuele voorraad per artikel
CREATE VIEW v_product_inventory AS
SELECT
    p.id as product_id,
    p.product_code,
    p.name as product_name,
    p.unit,
    COALESCE(SUM(i.quantity_available), 0) as total_available,
    COALESCE(SUM(i.quantity_reserved), 0) as total_reserved,
    COALESCE(SUM(i.quantity_on_order), 0) as total_on_order,
    COALESCE(SUM(i.quantity_physical), 0) as total_physical,
    p.minimum_stock,
    p.reorder_point,
    CASE
        WHEN COALESCE(SUM(i.quantity_available), 0) <= p.reorder_point THEN true
        ELSE false
    END as needs_reorder
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
WHERE p.is_active = true
GROUP BY p.id, p.product_code, p.name, p.unit, p.minimum_stock, p.reorder_point;

-- View: Open inkooporders
CREATE VIEW v_open_purchase_orders AS
SELECT
    po.id,
    po.order_number,
    po.order_date,
    po.expected_delivery_date,
    po.status,
    s.company_name as supplier_name,
    s.supplier_code,
    po.total_amount,
    COUNT(pol.id) as line_count,
    SUM(CASE WHEN pol.quantity_outstanding > 0 THEN 1 ELSE 0 END) as outstanding_lines
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.id
LEFT JOIN purchase_order_lines pol ON po.id = pol.purchase_order_id
WHERE po.status NOT IN ('geleverd', 'geannuleerd')
GROUP BY po.id, po.order_number, po.order_date, po.expected_delivery_date,
         po.status, s.company_name, s.supplier_code, po.total_amount;

-- View: Open verkooporders
CREATE VIEW v_open_sales_orders AS
SELECT
    so.id,
    so.order_number,
    so.order_date,
    so.requested_delivery_date,
    so.status,
    c.company_name as customer_name,
    c.customer_code,
    so.total_amount,
    COUNT(sol.id) as line_count,
    SUM(CASE WHEN sol.quantity_outstanding > 0 THEN 1 ELSE 0 END) as outstanding_lines
FROM sales_orders so
JOIN customers c ON so.customer_id = c.id
LEFT JOIN sales_order_lines sol ON so.id = sol.sales_order_id
WHERE so.status NOT IN ('geleverd', 'gefactureerd', 'geannuleerd')
GROUP BY so.id, so.order_number, so.order_date, so.requested_delivery_date,
         so.status, c.company_name, c.customer_code, so.total_amount;

-- ============================================
-- INDEXEN
-- ============================================

-- Users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- Suppliers
CREATE INDEX idx_suppliers_code ON suppliers(supplier_code);
CREATE INDEX idx_suppliers_active ON suppliers(is_active);

-- Customers
CREATE INDEX idx_customers_code ON customers(customer_code);
CREATE INDEX idx_customers_active ON customers(is_active);

-- Products
CREATE INDEX idx_products_code ON products(product_code);
CREATE INDEX idx_products_ean ON products(ean_code);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_supplier ON products(default_supplier_id);

-- Warehouse locations
CREATE INDEX idx_locations_code ON warehouse_locations(location_code);
CREATE INDEX idx_locations_warehouse ON warehouse_locations(warehouse);

-- Purchase orders
CREATE INDEX idx_po_number ON purchase_orders(order_number);
CREATE INDEX idx_po_supplier ON purchase_orders(supplier_id);
CREATE INDEX idx_po_status ON purchase_orders(status);
CREATE INDEX idx_po_date ON purchase_orders(order_date);

-- Purchase order lines
CREATE INDEX idx_pol_order ON purchase_order_lines(purchase_order_id);
CREATE INDEX idx_pol_product ON purchase_order_lines(product_id);

-- Sales orders
CREATE INDEX idx_so_number ON sales_orders(order_number);
CREATE INDEX idx_so_customer ON sales_orders(customer_id);
CREATE INDEX idx_so_status ON sales_orders(status);
CREATE INDEX idx_so_date ON sales_orders(order_date);

-- Sales order lines
CREATE INDEX idx_sol_order ON sales_order_lines(sales_order_id);
CREATE INDEX idx_sol_product ON sales_order_lines(product_id);

-- Inventory
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_location ON inventory(location_id);

-- Inventory transactions
CREATE INDEX idx_invtrans_number ON inventory_transactions(transaction_number);
CREATE INDEX idx_invtrans_date ON inventory_transactions(transaction_date);
CREATE INDEX idx_invtrans_type ON inventory_transactions(transaction_type);
CREATE INDEX idx_invtrans_product ON inventory_transactions(product_id);
CREATE INDEX idx_invtrans_reference ON inventory_transactions(reference_type, reference_id);

-- ============================================
-- FUNCTIES EN TRIGGERS
-- ============================================

-- Functie: Update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers voor updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sales_orders_updated_at BEFORE UPDATE ON sales_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- COMMENTS VOOR DOCUMENTATIE
-- ============================================

COMMENT ON TABLE users IS 'Gebruikers van het systeem';
COMMENT ON TABLE suppliers IS 'Leveranciers van artikelen';
COMMENT ON TABLE customers IS 'Klanten die artikelen afnemen';
COMMENT ON TABLE products IS 'Artikelstam met alle producten';
COMMENT ON TABLE warehouse_locations IS 'Fysieke locaties in het magazijn';
COMMENT ON TABLE purchase_orders IS 'Inkooporders bij leveranciers';
COMMENT ON TABLE purchase_order_lines IS 'Regels van inkooporders';
COMMENT ON TABLE sales_orders IS 'Verkooporders van klanten';
COMMENT ON TABLE sales_order_lines IS 'Regels van verkooporders';
COMMENT ON TABLE inventory IS 'Actuele voorraad per artikel en locatie';
COMMENT ON TABLE inventory_transactions IS 'Alle voorraadmutaties';
