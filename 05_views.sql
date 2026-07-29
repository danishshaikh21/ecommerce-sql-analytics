-- ==============================================================================
-- E-COMMERCE PRODUCTION SQL VIEWS
-- Dialect: PostgreSQL / Standard ANSI SQL
-- Description: Business Intelligence Views designed for PowerBI, Tableau, & Looker.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- VIEW 1: vw_executive_kpi_summary
-- Provides monthly aggregate KPIs for executive dashboards.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_executive_kpi_summary AS
SELECT 
    TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS active_customers,
    SUM(oi.line_total) AS gross_revenue,
    SUM(o.shipping_cost) AS shipping_revenue,
    SUM(oi.line_total) + SUM(o.shipping_cost) AS net_revenue,
    SUM(oi.quantity * p.unit_cost) AS total_cogs,
    SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost) AS gross_profit,
    ROUND(
        ((SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost)) / NULLIF(SUM(oi.line_total), 0)) * 100, 2
    ) AS gross_margin_pct,
    ROUND(SUM(oi.line_total) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM');


-- ------------------------------------------------------------------------------
-- VIEW 2: vw_customer_360
-- Complete Customer 360 view aggregating purchasing history, recency & spend.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_360 AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    c.city,
    c.state,
    c.customer_segment,
    c.created_at AS signup_date,
    COUNT(DISTINCT o.order_id) AS total_orders_placed,
    COALESCE(SUM(oi.line_total), 0) AS lifetime_value_clv,
    ROUND(COALESCE(AVG(oi.line_total), 0), 2) AS avg_item_spend,
    MAX(o.order_date) AS last_order_date,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(o.order_date)) AS recency_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'Completed'
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state, c.customer_segment, c.created_at;


-- ------------------------------------------------------------------------------
-- VIEW 3: vw_product_performance_matrix
-- Product catalog metrics, stock status, profit margins & units sold.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_performance_matrix AS
SELECT 
    p.product_id,
    p.product_name,
    cat.category_name,
    sup.supplier_name,
    p.unit_cost,
    p.unit_price,
    (p.unit_price - p.unit_cost) AS unit_margin,
    p.stock_quantity,
    p.reorder_level,
    CASE WHEN p.stock_quantity <= p.reorder_level THEN 'Reorder Required' ELSE 'Sufficient Stock' END AS stock_status,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(SUM(oi.line_total), 0) AS total_revenue,
    COALESCE(SUM(oi.quantity * p.unit_cost), 0) AS total_cogs,
    COALESCE(SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost), 0) AS total_profit
FROM products p
JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN suppliers sup ON p.supplier_id = sup.supplier_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, cat.category_name, sup.supplier_name, p.unit_cost, p.unit_price, p.stock_quantity, p.reorder_level;


-- ------------------------------------------------------------------------------
-- VIEW 4: vw_monthly_category_sales
-- Category-level sales trend matrix for category management teams.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_category_sales AS
SELECT 
    TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
    cat.category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.line_total) AS category_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE o.order_status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM'), cat.category_name;


-- ------------------------------------------------------------------------------
-- VIEW 5: vw_daily_sales_velocity
-- Daily revenue tracking with 7-day and 30-day moving averages.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_daily_sales_velocity AS
WITH daily_agg AS (
    SELECT 
        DATE(o.order_date) AS sales_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.line_total) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE(o.order_date)
)
SELECT 
    sales_date,
    total_orders,
    daily_revenue,
    ROUND(AVG(daily_revenue) OVER (ORDER BY sales_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_7day_avg,
    ROUND(AVG(daily_revenue) OVER (ORDER BY sales_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS rolling_30day_avg
FROM daily_agg;


-- ------------------------------------------------------------------------------
-- VIEW 6: vw_supplier_fulfillment_performance
-- Vendor quality metrics, total margin, and order failure rate.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_supplier_fulfillment_performance AS
SELECT 
    s.supplier_id,
    s.supplier_name,
    s.country,
    s.rating,
    COUNT(DISTINCT p.product_id) AS total_products_supplied,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue_generated,
    SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost) AS gross_profit_generated,
    ROUND(
        ((SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost)) / NULLIF(SUM(oi.line_total), 0)) * 100, 2
    ) AS supplier_margin_pct
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status = 'Completed'
GROUP BY s.supplier_id, s.supplier_name, s.country, s.rating;
