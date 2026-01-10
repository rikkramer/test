# PostgreSQL Database - Inkoop/Verkoop & Voorraadbeheer

Een complete database voor het beheren van inkoop, verkoop, artikelstam en voorraad voor een handelsbedrijf.

## 📋 Overzicht

Deze database bevat alle functionaliteit voor:
- **Artikelbeheer**: Complete artikelstam met prijzen, voorraadniveaus en leveranciers
- **Inkoop**: Leveranciers, inkooporders en goederenontvangst
- **Verkoop**: Klanten, verkooporders en leveringen
- **Voorraadbeheer**: Magazijnlocaties, voorraad en mutaties

## 🗂️ Database Structuur

### Stamgegevens

#### `users`
Gebruikers van het systeem voor authenticatie en autorisatie.

#### `suppliers`
Leveranciers met complete contactgegevens en betalingscondities.

#### `customers`
Klanten met factuur- en leveradressen, kredietlimieten en betalingscondities.

#### `products`
Artikelstam met alle productinformatie:
- Product codes, EAN, SKU
- Naam en omschrijving
- Inkoop- en verkoopprijzen
- Voorraadniveaus (minimum, maximum, bestelmoment)
- Afmetingen en gewicht
- BTW tarieven

#### `warehouse_locations`
Fysieke magazijnlocaties met indeling:
- Magazijn
- Gang (aisle)
- Rek (rack)
- Plank (shelf)
- Vak (bin)

### Transacties

#### `purchase_orders` & `purchase_order_lines`
Inkooporders bij leveranciers:
- Ordernummer en datum
- Leverancier
- Verwachte en werkelijke leverdatum
- Status: concept, besteld, deels_geleverd, geleverd, geannuleerd
- Regels met artikelen, aantallen en prijzen
- Automatische berekening openstaande hoeveelheden

#### `sales_orders` & `sales_order_lines`
Verkooporders van klanten:
- Ordernummer en datum
- Klant
- Gewenste en werkelijke leverdatum
- Status: concept, bevestigd, deels_geleverd, geleverd, gefactureerd, geannuleerd
- Regels met artikelen, aantallen, prijzen en kortingen
- Automatische berekening openstaande hoeveelheden

### Voorraad

#### `inventory`
Actuele voorraad per artikel en locatie:
- Beschikbare voorraad
- Gereserveerde voorraad
- Voorraad in bestelling
- Fysieke voorraad (berekend)
- Laatste tellingen

#### `inventory_transactions`
Alle voorraadmutaties met volledige traceerbaarheid:
- Transactienummer en datum
- Type: inkoop, verkoop, correctie, verplaatsing, retour
- Artikel en hoeveelheid
- Van/naar locaties
- Referenties naar orders
- Kostprijzen

## 📊 Views

De database bevat handige views voor rapportages:

### `v_product_inventory`
Overzicht van voorraad per artikel:
```sql
SELECT * FROM v_product_inventory
WHERE needs_reorder = true;
```

Toont:
- Totale beschikbare, gereserveerde en fysieke voorraad
- Voorraad in bestelling
- Minimum stock en bestelmoment
- Indicator of herbevoorrading nodig is

### `v_open_purchase_orders`
Overzicht van openstaande inkooporders:
```sql
SELECT * FROM v_open_purchase_orders
ORDER BY expected_delivery_date;
```

Toont:
- Ordernummer en leverancier
- Datums en status
- Aantal regels en openstaande regels
- Totaalbedrag

### `v_open_sales_orders`
Overzicht van openstaande verkooporders:
```sql
SELECT * FROM v_open_sales_orders
ORDER BY requested_delivery_date;
```

Toont:
- Ordernummer en klant
- Datums en status
- Aantal regels en openstaande regels
- Totaalbedrag

## 🚀 Installatie

### 1. Database aanmaken

```bash
# Login als postgres gebruiker
sudo -u postgres psql

# Maak database aan
CREATE DATABASE bedrijf_erp;

# Maak gebruiker aan (optioneel)
CREATE USER erp_user WITH PASSWORD 'jouw_wachtwoord';
GRANT ALL PRIVILEGES ON DATABASE bedrijf_erp TO erp_user;

# Verbind met de database
\c bedrijf_erp
```

### 2. Schema installeren

```bash
# Voer het schema uit
psql -U erp_user -d bedrijf_erp -f database/schema.sql
```

Of vanuit PostgreSQL:
```sql
\i database/schema.sql
```

### 3. Demo data laden (optioneel)

```bash
# Voer de seed data uit
psql -U erp_user -d bedrijf_erp -f database/seeds/01_demo_data.sql
```

Of vanuit PostgreSQL:
```sql
\i database/seeds/01_demo_data.sql
```

## 📖 Gebruik Voorbeelden

### Producten met lage voorraad opvragen

```sql
SELECT
    product_code,
    product_name,
    total_available,
    minimum_stock,
    reorder_point
FROM v_product_inventory
WHERE total_available <= reorder_point
ORDER BY total_available;
```

### Nieuwe verkooporder aanmaken

```sql
-- Stap 1: Maak order aan
INSERT INTO sales_orders (
    order_number,
    customer_id,
    order_date,
    requested_delivery_date,
    status,
    created_by
) VALUES (
    'SO-2026-003',
    (SELECT id FROM customers WHERE customer_code = 'KL001'),
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    'concept',
    (SELECT id FROM users WHERE username = 'verkoper')
);

-- Stap 2: Voeg regels toe
INSERT INTO sales_order_lines (
    sales_order_id,
    line_number,
    product_id,
    quantity,
    unit_price
) VALUES (
    (SELECT id FROM sales_orders WHERE order_number = 'SO-2026-003'),
    1,
    (SELECT id FROM products WHERE product_code = 'ART001'),
    5,
    999.00
);

-- Stap 3: Bereken totalen en update status
UPDATE sales_orders
SET status = 'bevestigd',
    subtotal = (SELECT SUM(line_total) FROM sales_order_lines WHERE sales_order_id = sales_orders.id),
    vat_amount = (SELECT SUM(line_total * vat_rate / 100) FROM sales_order_lines WHERE sales_order_id = sales_orders.id),
    total_amount = subtotal + vat_amount
WHERE order_number = 'SO-2026-003';
```

### Voorraad bijwerken na goederenontvangst

```sql
-- Stap 1: Update inkooporder regel
UPDATE purchase_order_lines
SET quantity_received = quantity_received + 10
WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE order_number = 'PO-2026-002')
  AND line_number = 1;

-- Stap 2: Registreer voorraadmutatie
INSERT INTO inventory_transactions (
    transaction_number,
    transaction_type,
    product_id,
    to_location_id,
    quantity,
    reference_type,
    reference_id,
    unit_cost
) VALUES (
    'IT-2026-004',
    'inkoop',
    (SELECT product_id FROM purchase_order_lines
     WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE order_number = 'PO-2026-002')
     AND line_number = 1),
    (SELECT id FROM warehouse_locations WHERE location_code = 'A-01-01-01'),
    10,
    'purchase_order',
    (SELECT id FROM purchase_orders WHERE order_number = 'PO-2026-002'),
    25.00
);

-- Stap 3: Update inventory
INSERT INTO inventory (product_id, location_id, quantity_available)
VALUES (
    (SELECT product_id FROM purchase_order_lines
     WHERE purchase_order_id = (SELECT id FROM purchase_orders WHERE order_number = 'PO-2026-002')
     AND line_number = 1),
    (SELECT id FROM warehouse_locations WHERE location_code = 'A-01-01-01'),
    10
)
ON CONFLICT (product_id, location_id)
DO UPDATE SET
    quantity_available = inventory.quantity_available + 10,
    updated_at = CURRENT_TIMESTAMP;
```

### Omzet per klant

```sql
SELECT
    c.customer_code,
    c.company_name,
    COUNT(DISTINCT so.id) as aantal_orders,
    SUM(so.total_amount) as totale_omzet,
    AVG(so.total_amount) as gemiddelde_orderwaarde
FROM customers c
LEFT JOIN sales_orders so ON c.id = so.customer_id
WHERE so.status NOT IN ('geannuleerd')
  AND so.order_date >= '2026-01-01'
GROUP BY c.id, c.customer_code, c.company_name
ORDER BY totale_omzet DESC;
```

### Voorraadwaarde berekenen

```sql
SELECT
    p.product_code,
    p.name,
    i.quantity_physical,
    p.purchase_price,
    (i.quantity_physical * p.purchase_price) as voorraadwaarde
FROM inventory i
JOIN products p ON i.product_id = p.id
WHERE i.quantity_physical > 0
ORDER BY voorraadwaarde DESC;
```

## 🔒 Beveiliging

### Wachtwoorden
De demo data bevat placeholder password hashes. In productie:

```sql
-- Gebruik bcrypt voor wachtwoord hashing
-- Bijvoorbeeld met pgcrypto extension:
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Wachtwoord hashen bij insert
INSERT INTO users (username, email, password_hash, first_name, last_name)
VALUES (
    'newuser',
    'user@example.com',
    crypt('het_wachtwoord', gen_salt('bf')),
    'Voornaam',
    'Achternaam'
);

-- Wachtwoord valideren
SELECT * FROM users
WHERE username = 'newuser'
  AND password_hash = crypt('het_wachtwoord', password_hash);
```

### Gebruikersrechten

```sql
-- Alleen-lezen gebruiker
CREATE USER readonly_user WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE bedrijf_erp TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- Magazijn gebruiker (alleen voorraad)
CREATE USER warehouse_user WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE bedrijf_erp TO warehouse_user;
GRANT USAGE ON SCHEMA public TO warehouse_user;
GRANT SELECT, INSERT, UPDATE ON inventory, inventory_transactions, warehouse_locations TO warehouse_user;
GRANT SELECT ON products, purchase_orders, sales_orders TO warehouse_user;
```

## 📈 Onderhoud

### Vacuum en Analyze

```sql
-- Regelmatig uitvoeren voor optimale performance
VACUUM ANALYZE;

-- Voor specifieke tabellen
VACUUM ANALYZE inventory;
VACUUM ANALYZE inventory_transactions;
```

### Backup

```bash
# Volledige database backup
pg_dump -U erp_user bedrijf_erp > backup_$(date +%Y%m%d).sql

# Alleen schema
pg_dump -U erp_user --schema-only bedrijf_erp > schema_backup.sql

# Alleen data
pg_dump -U erp_user --data-only bedrijf_erp > data_backup.sql
```

### Restore

```bash
# Restore van backup
psql -U erp_user bedrijf_erp < backup_20260110.sql
```

## 🔄 Automatische Updates

De database heeft triggers voor:
- Automatische update van `updated_at` timestamps
- Automatische berekening van totalen in orderregels
- Automatische berekening van openstaande hoeveelheden

## 📊 Database Schema Diagram

```
users
  ├── purchase_orders (created_by)
  ├── sales_orders (created_by)
  └── inventory_transactions (created_by)

suppliers
  ├── products (default_supplier_id)
  └── purchase_orders (supplier_id)
      └── purchase_order_lines
          └── products

customers
  └── sales_orders (customer_id)
      └── sales_order_lines
          └── products

products
  ├── inventory (product_id)
  ├── purchase_order_lines (product_id)
  ├── sales_order_lines (product_id)
  └── inventory_transactions (product_id)

warehouse_locations
  ├── inventory (location_id)
  └── inventory_transactions (from/to_location_id)
```

## 📝 Opmerkingen

- Alle ID's zijn UUID voor betere schaalbaarheid en veiligheid
- Prijzen worden opgeslagen als DECIMAL(15,2) voor nauwkeurigheid
- Timestamps worden automatisch bijgewerkt via triggers
- Foreign keys hebben ON DELETE CASCADE waar logisch
- Indexen zijn aangemaakt op veel gebruikte velden voor betere performance
- Generated columns worden gebruikt voor berekende velden

## 🆘 Support

Voor vragen of problemen, raadpleeg:
- PostgreSQL documentatie: https://www.postgresql.org/docs/
- Database schema: `database/schema.sql`
- Demo data: `database/seeds/01_demo_data.sql`

## 📄 Licentie

MIT
