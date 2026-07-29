-- ==============================================================================
-- E-COMMERCE STORED PROCEDURES
-- Dialect: PostgreSQL (PL/pgSQL) / Standard ANSI SQL Stored Procedures
-- Description: Automated business process workflows, segmentation & transactions.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- PROCEDURE 1: sp_recalculate_customer_segments
-- Automates customer tier upgrade/downgrade based on lifetime spend thresholds.
-- Thresholds: Enterprise ($10k+), VIP ($5k+), Gold ($2k+), Silver ($500+), Standard (<$500)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_recalculate_customer_segments()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update Enterprise Segment
    UPDATE customers
    SET customer_segment = 'Enterprise'
    WHERE customer_id IN (
        SELECT o.customer_id
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'Completed'
        GROUP BY o.customer_id
        HAVING SUM(oi.line_total) >= 10000.00
    );

    -- Update VIP Segment
    UPDATE customers
    SET customer_segment = 'VIP'
    WHERE customer_id IN (
        SELECT o.customer_id
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'Completed'
        GROUP BY o.customer_id
        HAVING SUM(oi.line_total) >= 5000.00 AND SUM(oi.line_total) < 10000.00
    );

    -- Update Gold Segment
    UPDATE customers
    SET customer_segment = 'Gold'
    WHERE customer_id IN (
        SELECT o.customer_id
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'Completed'
        GROUP BY o.customer_id
        HAVING SUM(oi.line_total) >= 2000.00 AND SUM(oi.line_total) < 5000.00
    );

    -- Update Silver Segment
    UPDATE customers
    SET customer_segment = 'Silver'
    WHERE customer_id IN (
        SELECT o.customer_id
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.order_status = 'Completed'
        GROUP BY o.customer_id
        HAVING SUM(oi.line_total) >= 500.00 AND SUM(oi.line_total) < 2000.00
    );

    -- Log Execution in Audit Table
    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('customers', 'SEGMENT_RECALCULATION', 0, 'Customer RFM spend tiers updated successfully.');
END;
$$;


-- ------------------------------------------------------------------------------
-- PROCEDURE 2: sp_process_new_order (Transaction-Safe ACID Stored Procedure)
-- Handles order placement, inventory deduction, payment logging, and audit.
-- Rolls back transaction if stock is insufficient or customer does not exist.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_process_new_order(
    p_customer_id INT,
    p_product_id INT,
    p_quantity INT,
    p_payment_method VARCHAR(30),
    p_shipping_cost DECIMAL(8,2),
    p_sales_channel VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_unit_price DECIMAL(10,2);
    v_stock INT;
    v_order_id INT;
    v_line_total DECIMAL(10,2);
BEGIN
    -- 1. Check Product Stock & Price
    SELECT unit_price, stock_quantity INTO v_unit_price, v_stock
    FROM products
    WHERE product_id = p_product_id AND is_active = TRUE;

    IF v_unit_price IS NULL THEN
        RAISE EXCEPTION 'Product ID % is inactive or does not exist.', p_product_id;
    END IF;

    IF v_stock < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock for product ID %. Available: %, Requested: %', p_product_id, v_stock, p_quantity;
    END IF;

    -- 2. Insert Order Header
    INSERT INTO orders (customer_id, order_date, order_status, shipping_cost, sales_channel)
    VALUES (p_customer_id, CURRENT_TIMESTAMP, 'Completed', p_shipping_cost, p_sales_channel)
    RETURNING order_id INTO v_order_id;

    -- 3. Insert Order Line Item
    v_line_total := (p_quantity * v_unit_price);
    INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_amount)
    VALUES (v_order_id, p_product_id, p_quantity, v_unit_price, 0.00);

    -- 4. Deduct Stock Quantity
    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;

    -- 5. Insert Payment Record
    INSERT INTO payments (order_id, payment_date, payment_method, payment_status, amount_paid, transaction_reference)
    VALUES (v_order_id, CURRENT_TIMESTAMP, p_payment_method, 'Completed', v_line_total + p_shipping_cost, CONCAT('TXN-PROC-', v_order_id));

    -- 6. Log Audit Trail
    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('orders', 'ORDER_CREATED', v_order_id, CONCAT('Order processed successfully for Customer ID ', p_customer_id));

END;
$$;


-- ------------------------------------------------------------------------------
-- PROCEDURE 3: sp_generate_monthly_executive_report
-- Computes and prints a summary for a given year and month.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_generate_monthly_executive_report(
    p_year INT,
    p_month INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_rev DECIMAL(12,2);
    v_total_orders INT;
    v_aov DECIMAL(10,2);
BEGIN
    SELECT 
        COALESCE(SUM(oi.line_total), 0),
        COUNT(DISTINCT o.order_id),
        ROUND(COALESCE(SUM(oi.line_total) / NULLIF(COUNT(DISTINCT o.order_id), 0), 0), 2)
    INTO v_total_rev, v_total_orders, v_aov
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = p_year
      AND EXTRACT(MONTH FROM o.order_date) = p_month
      AND o.order_status = 'Completed';

    RAISE NOTICE '==================================================';
    RAISE NOTICE 'EXECUTIVE MONTHLY REPORT: %-%', p_year, LPAD(p_month::text, 2, '0');
    RAISE NOTICE 'Total Orders: %', v_total_orders;
    RAISE NOTICE 'Total Revenue: $%', v_total_rev;
    RAISE NOTICE 'Average Order Value (AOV): $%', v_aov;
    RAISE NOTICE '==================================================';
END;
$$;
