-- ==============================================================================
-- E-COMMERCE DATABASE TRIGGERS & AUTOMATION
-- Dialect: PostgreSQL (PL/pgSQL) / Standard ANSI SQL Triggers
-- Description: Automated inventory management, order cancellation stock recovery,
--              and compliance audit logging triggers.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- TRIGGER 1: trg_update_stock_on_order_cancel
-- Restores product stock quantity whenever an order is set to 'Cancelled' or 'Returned'.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_restore_stock_on_cancel()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if order status changed to Cancelled or Returned
    IF (NEW.order_status IN ('Cancelled', 'Returned') AND OLD.order_status NOT IN ('Cancelled', 'Returned')) THEN
        
        -- Restore inventory stock for all line items in this order
        UPDATE products p
        SET stock_quantity = p.stock_quantity + oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.order_id
          AND oi.product_id = p.product_id;

        -- Log Audit Action
        INSERT INTO audit_logs (table_name, action_type, record_id, details)
        VALUES ('orders', 'STOCK_RESTORED', NEW.order_id, CONCAT('Inventory restored for cancelled/returned Order ID ', NEW.order_id));
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_restore_stock_on_cancel ON orders;

CREATE TRIGGER trg_restore_stock_on_cancel
AFTER UPDATE OF order_status ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_restore_stock_on_cancel();


-- ------------------------------------------------------------------------------
-- TRIGGER 2: trg_audit_customer_profile_changes
-- Logs historical changes to sensitive customer attributes (email, phone).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit_customer_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.email <> NEW.email THEN
        INSERT INTO audit_logs (table_name, action_type, record_id, details)
        VALUES ('customers', 'EMAIL_CHANGE', NEW.customer_id, CONCAT('Email changed from ', OLD.email, ' to ', NEW.email));
    END IF;

    IF OLD.phone <> NEW.phone THEN
        INSERT INTO audit_logs (table_name, action_type, record_id, details)
        VALUES ('customers', 'PHONE_CHANGE', NEW.customer_id, CONCAT('Phone changed from ', OLD.phone, ' to ', NEW.phone));
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_customer_changes ON customers;

CREATE TRIGGER trg_audit_customer_changes
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION fn_audit_customer_changes();


-- ------------------------------------------------------------------------------
-- TRIGGER 3: trg_enforce_min_product_price
-- Protects catalog data integrity by throwing an exception if unit_price < unit_cost.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_enforce_min_product_price()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.unit_price < NEW.unit_cost THEN
        RAISE EXCEPTION 'Catalog Error: Unit price ($%) cannot be lower than unit cost ($%) for product ID %', NEW.unit_price, NEW.unit_cost, NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_min_product_price ON products;

CREATE TRIGGER trg_enforce_min_product_price
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION fn_enforce_min_product_price();
