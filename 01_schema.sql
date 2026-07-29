-- ==============================================================================
-- E-COMMERCE SALES ANALYTICS DATABASE SCHEMA
-- Dialect: PostgreSQL / Standard ANSI SQL
-- Description: Production-grade DDL for high-volume enterprise e-commerce platform.
-- ==============================================================================

-- Drop existing tables if re-initializing (in reverse dependency order)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ------------------------------------------------------------------------------
-- 1. CATEGORIES TABLE
-- Represents product categories with hierarchical parent-child capability.
-- ------------------------------------------------------------------------------
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    parent_category_id INT REFERENCES categories(category_id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 2. SUPPLIERS TABLE
-- Stores details of product vendors and fulfillment suppliers.
-- ------------------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(30),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50) DEFAULT 'USA',
    rating DECIMAL(3, 2) CHECK (rating >= 0.00 AND rating <= 5.00),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 3. PRODUCTS TABLE
-- Master catalog of products, inventory stock levels, and cost structures.
-- ------------------------------------------------------------------------------
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE SET NULL,
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= unit_cost),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level INT NOT NULL DEFAULT 10,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 4. CUSTOMERS TABLE
-- Customer profiles, geographic segmentation, and acquisition dates.
-- ------------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(30),
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    customer_segment VARCHAR(30) DEFAULT 'Standard' CHECK (customer_segment IN ('Standard', 'Silver', 'Gold', 'VIP', 'Enterprise')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 5. ORDERS TABLE
-- Order header information tracking transaction dates, customer, and shipping.
-- ------------------------------------------------------------------------------
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(20) NOT NULL DEFAULT 'Completed' CHECK (order_status IN ('Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled', 'Returned')),
    shipping_cost DECIMAL(8, 2) DEFAULT 0.00 CHECK (shipping_cost >= 0),
    shipping_city VARCHAR(50),
    shipping_state VARCHAR(50),
    sales_channel VARCHAR(30) DEFAULT 'Web' CHECK (sales_channel IN ('Web', 'Mobile App', 'Marketplace', 'POS')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 6. ORDER_ITEMS TABLE
-- Line items associated with each order, tracking quantity, discounts & line total.
-- ------------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    line_total DECIMAL(10, 2) GENERATED ALWAYS AS ((quantity * unit_price) - discount_amount) STORED
);

-- ------------------------------------------------------------------------------
-- 7. PAYMENTS TABLE
-- Gateway payment transactions, methods, and status tracking.
-- ------------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(30) NOT NULL CHECK (payment_method IN ('Credit Card', 'PayPal', 'Apple Pay', 'Google Pay', 'BNPL', 'Bank Transfer')),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Completed' CHECK (payment_status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    amount_paid DECIMAL(10, 2) NOT NULL CHECK (amount_paid >= 0),
    transaction_reference VARCHAR(100) UNIQUE
);

-- ------------------------------------------------------------------------------
-- 8. AUDIT_LOGS TABLE
-- System logs populated via database triggers for security and order audits.
-- ------------------------------------------------------------------------------
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    record_id INT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
