-- ==============================================================================
-- E-COMMERCE DATA CLEANING & VALIDATION SCRIPT
-- Dialect: PostgreSQL / Standard ANSI SQL
-- Description: Sanitization, deduplication, timestamp validation, & data quality audits.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TRIM WHITESPACE & STANDARDIZE TEXT FIELDS
-- Removes leading/trailing spaces and converts city/state names to canonical formats.
-- ------------------------------------------------------------------------------
UPDATE customers
SET first_name = TRIM(first_name),
    last_name = TRIM(last_name),
    email = LOWER(TRIM(email)),
    city = INITCAP(TRIM(city)),
    state = UPPER(TRIM(state));

UPDATE suppliers
SET supplier_name = TRIM(supplier_name),
    email = LOWER(TRIM(email)),
    city = INITCAP(TRIM(city)),
    state = UPPER(TRIM(state));

-- ------------------------------------------------------------------------------
-- 2. HANDLE MISSING OR NULL VALUES (FALLBACK DEFAULTS)
-- Populates null phone numbers and missing postal codes with standard indicators.
-- ------------------------------------------------------------------------------
UPDATE customers
SET phone = '+1-555-000-0000'
WHERE phone IS NULL OR phone = '';

UPDATE customers
SET postal_code = '00000'
WHERE postal_code IS NULL OR postal_code = '';

-- ------------------------------------------------------------------------------
-- 3. DETECT & REMOVE DUPLICATE CUSTOMER RECORDS
-- Retains the earliest registered customer record when duplicate emails exist.
-- ------------------------------------------------------------------------------
WITH duplicate_customers AS (
    SELECT customer_id,
           ROW_NUMBER() OVER (
               PARTITION BY LOWER(email) 
               ORDER BY created_at ASC, customer_id ASC
           ) AS row_num
    FROM customers
)
DELETE FROM customers
WHERE customer_id IN (
    SELECT customer_id 
    FROM duplicate_customers 
    WHERE row_num > 1
);

-- ------------------------------------------------------------------------------
-- 4. VALIDATE & CORRECT ANOMALOUS DISCOUNTS
-- Caps discount_amount so that it cannot exceed the gross line price.
-- ------------------------------------------------------------------------------
UPDATE order_items
SET discount_amount = (quantity * unit_price)
WHERE discount_amount > (quantity * unit_price);

-- ------------------------------------------------------------------------------
-- 5. TIMESTAMP ANOMALY AUDIT (ORPHAN OR PRE-SIGNUP ORDERS)
-- Logs any order created BEFORE the customer account creation timestamp.
-- ------------------------------------------------------------------------------
INSERT INTO audit_logs (table_name, action_type, record_id, details)
SELECT 
    'orders' AS table_name,
    'ANOMALY_DETECTED' AS action_type,
    o.order_id AS record_id,
    CONCAT('Order date (', o.order_date, ') is prior to customer signup date (', c.created_at, ')') AS details
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date < c.created_at;

-- Re-align anomalous order dates to match customer created_at timestamp
UPDATE orders o
SET order_date = c.created_at + INTERVAL '5 minutes'
FROM customers c
WHERE o.customer_id = c.customer_id
  AND o.order_date < c.created_at;

-- ------------------------------------------------------------------------------
-- 6. ORPHAN RECORD AUDIT (REFERENTIAL INTEGRITY SANITY CHECK)
-- Detects order items or payments without matching header records.
-- ------------------------------------------------------------------------------
-- Audit orphan order items
INSERT INTO audit_logs (table_name, action_type, record_id, details)
SELECT 
    'order_items' AS table_name,
    'ORPHAN_ITEM' AS action_type,
    order_item_id AS record_id,
    CONCAT('Order item references non-existent order_id ', order_id) AS details
FROM order_items
WHERE order_id NOT IN (SELECT order_id FROM orders);

-- Audit orphan payments
INSERT INTO audit_logs (table_name, action_type, record_id, details)
SELECT 
    'payments' AS table_name,
    'ORPHAN_PAYMENT' AS action_type,
    payment_id AS record_id,
    CONCAT('Payment references non-existent order_id ', order_id) AS details
FROM payments
WHERE order_id NOT IN (SELECT order_id FROM orders);

-- ------------------------------------------------------------------------------
-- 7. RE-CALCULATE & VERIFY PAYMENT AMOUNT ACCURACY
-- Ensures amount_paid in payments table equals (subtotal + shipping_cost).
-- ------------------------------------------------------------------------------
WITH order_totals AS (
    SELECT 
        o.order_id,
        COALESCE(SUM(oi.line_total), 0) + o.shipping_cost AS calculated_total
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.shipping_cost
)
UPDATE payments p
SET amount_paid = ot.calculated_total
FROM order_totals ot
WHERE p.order_id = ot.order_id
  AND p.payment_status = 'Completed'
  AND p.amount_paid <> ot.calculated_total;

-- Summary statement
SELECT 'Data cleaning script executed successfully. Database sanitized.' AS status_message;
