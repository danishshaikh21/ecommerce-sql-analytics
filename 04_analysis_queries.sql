-- ==============================================================================
-- E-COMMERCE ADVANCED SQL ANALYTICS QUERY SUITE
-- Dialect: PostgreSQL / Standard ANSI SQL
-- Description: 50 Production-Grade Business Analytics Queries covering Revenue,
--              Customer LTV, RFM, Cohort Retention, Inventory, & Market Basket.
-- ==============================================================================

-- ==============================================================================
-- DOMAIN 1: EXECUTIVE SUMMARY & REVENUE METRICS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Question 1: Executive KPI Overview (Total Revenue, Orders, AOV, Total Units)
-- Concepts: Aggregations (SUM, COUNT, AVG), JOIN, CASE WHEN
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS gross_revenue,
    SUM(o.shipping_cost) AS total_shipping_revenue,
    SUM(oi.line_total) + SUM(o.shipping_cost) AS total_net_revenue,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2) AS average_order_value_aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status IN ('Completed', 'Shipped', 'Processing');


-- ------------------------------------------------------------------------------
-- Question 2: Monthly Revenue & Month-over-Month (MoM) Growth Rate
-- Concepts: CTEs, DATE_TRUNC / EXTRACT, LAG() Window Function, Growth % Math
-- ------------------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT 
        TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
        SUM(oi.line_total) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
)
SELECT 
    sales_month,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY sales_month) AS prior_month_revenue,
    ROUND(
        ((revenue - LAG(revenue, 1) OVER (ORDER BY sales_month)) / 
        NULLIF(LAG(revenue, 1) OVER (ORDER BY sales_month), 0)) * 100, 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY sales_month;


-- ------------------------------------------------------------------------------
-- Question 3: Quarterly Revenue & Year-over-Year (YoY) Performance Comparison
-- Concepts: EXTRACT(YEAR/QUARTER), CTEs, Self-Join / LAG(4)
-- ------------------------------------------------------------------------------
WITH quarterly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM o.order_date) AS sales_year,
        EXTRACT(QUARTER FROM o.order_date) AS sales_quarter,
        SUM(oi.line_total) AS quarterly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY EXTRACT(YEAR FROM o.order_date), EXTRACT(QUARTER FROM o.order_date)
)
SELECT 
    sales_year,
    sales_quarter,
    quarterly_revenue,
    LAG(quarterly_revenue, 4) OVER (ORDER BY sales_year, sales_quarter) AS prior_year_quarter_revenue,
    ROUND(
        ((quarterly_revenue - LAG(quarterly_revenue, 4) OVER (ORDER BY sales_year, sales_quarter)) /
        NULLIF(LAG(quarterly_revenue, 4) OVER (ORDER BY sales_year, sales_quarter), 0)) * 100, 2
    ) AS yoy_quarterly_growth_pct
FROM quarterly_sales
ORDER BY sales_year, sales_quarter;


-- ------------------------------------------------------------------------------
-- Question 4: Daily Sales Velocity & 7-Day Rolling Moving Average Revenue
-- Concepts: CTE, Window Frame (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- ------------------------------------------------------------------------------
WITH daily_sales AS (
    SELECT 
        DATE(o.order_date) AS sales_date,
        SUM(oi.line_total) AS daily_revenue,
        COUNT(DISTINCT o.order_id) AS daily_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE(o.order_date)
)
SELECT 
    sales_date,
    daily_revenue,
    daily_orders,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_7day_avg_revenue
FROM daily_sales
ORDER BY sales_date DESC
LIMIT 30;


-- ------------------------------------------------------------------------------
-- Question 5: Top 5 Revenue-Generating States & Contribution Percentage
-- Concepts: SUM OVER () Window aggregate, Percentage of total calculation
-- ------------------------------------------------------------------------------
WITH state_sales AS (
    SELECT 
        o.shipping_state,
        SUM(oi.line_total) AS state_revenue,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.shipping_state
)
SELECT 
    shipping_state,
    state_revenue,
    order_count,
    ROUND((state_revenue / SUM(state_revenue) OVER ()) * 100, 2) AS pct_total_revenue
FROM state_sales
ORDER BY state_revenue DESC
LIMIT 5;


-- ------------------------------------------------------------------------------
-- Question 6: Category Revenue, COGS, and Gross Profit Margin Analysis
-- Concepts: Multi-table JOINs (4 tables), Profit Formula, Profit Margin %
-- ------------------------------------------------------------------------------
SELECT 
    c.category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.unit_price - oi.discount_amount) AS category_revenue,
    SUM(oi.quantity * p.unit_cost) AS category_cogs,
    SUM(oi.quantity * oi.unit_price - oi.discount_amount) - SUM(oi.quantity * p.unit_cost) AS gross_profit,
    ROUND(
        ((SUM(oi.quantity * oi.unit_price - oi.discount_amount) - SUM(oi.quantity * p.unit_cost)) /
        NULLIF(SUM(oi.quantity * oi.unit_price - oi.discount_amount), 0)) * 100, 2
    ) AS gross_margin_pct
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.category_id, c.category_name
ORDER BY gross_profit DESC;


-- ------------------------------------------------------------------------------
-- Question 7: Cumulative Platform Revenue Trajectory Over Time
-- Concepts: Window Aggregate SUM() OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)
-- ------------------------------------------------------------------------------
WITH monthly_totals AS (
    SELECT 
        TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
        SUM(oi.line_total) AS month_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
)
SELECT 
    sales_month,
    month_revenue,
    SUM(month_revenue) OVER (ORDER BY sales_month ROWS UNBOUNDED PRECEDING) AS cumulative_revenue
FROM monthly_totals
ORDER BY sales_month;


-- ------------------------------------------------------------------------------
-- Question 8: Sales Breakdown by Channel (Web, Mobile, Marketplace, POS)
-- Concepts: GROUP BY, Percentage Calculation, Case Statement Metrics
-- ------------------------------------------------------------------------------
SELECT 
    o.sales_channel,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS channel_revenue,
    ROUND(AVG(oi.line_total), 2) AS avg_item_price,
    ROUND((SUM(oi.line_total) / SUM(SUM(oi.line_total)) OVER ()) * 100, 2) AS channel_revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY o.sales_channel
ORDER BY channel_revenue DESC;


-- ==============================================================================
-- DOMAIN 2: CUSTOMER 360, CLV, RFM & RETENTION
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Question 9: Top 20 High-Value Customers (Customer 360 Leaderboard)
-- Concepts: INNER JOIN, Aggregations, DENSE_RANK() Window Function
-- ------------------------------------------------------------------------------
WITH customer_totals AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.customer_segment,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.line_total) AS total_spent,
        ROUND(AVG(oi.line_total), 2) AS avg_order_item_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.customer_segment
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank,
    customer_id,
    customer_name,
    email,
    customer_segment,
    total_orders,
    total_spent,
    avg_order_item_value
FROM customer_totals
ORDER BY spend_rank
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Question 10: Customer Lifetime Value (CLV) by Signup Cohort Year
-- Concepts: DATE_TRUNC / EXTRACT(YEAR), Average CLV Calculation
-- ------------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT 
        c.customer_id,
        EXTRACT(YEAR FROM c.created_at) AS signup_year,
        COALESCE(SUM(oi.line_total), 0) AS lifetime_spend
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'Completed'
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, EXTRACT(YEAR FROM c.created_at)
)
SELECT 
    signup_year,
    COUNT(customer_id) AS total_customers,
    ROUND(SUM(lifetime_spend), 2) AS cohort_total_revenue,
    ROUND(AVG(lifetime_spend), 2) AS average_clv
FROM customer_spend
GROUP BY signup_year
ORDER BY signup_year;


-- ------------------------------------------------------------------------------
-- Question 11: RFM (Recency, Frequency, Monetary) Customer Segmentation
-- Concepts: NTILE(5) Window Function, CTEs, String Concatenation
-- ------------------------------------------------------------------------------
WITH max_date AS (
    SELECT MAX(order_date) AS ref_date FROM orders
),
rfm_raw AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        EXTRACT(DAY FROM (SELECT ref_date FROM max_date) - MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.line_total) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name
),
rfm_scores AS (
    SELECT 
        customer_id,
        customer_name,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_raw
)
SELECT 
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    CONCAT(r_score, f_score, m_score) AS rfm_combined,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'Promising / Recent'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk / Need Attention'
        ELSE 'Hibernating / Lost'
    END AS rfm_segment
FROM rfm_scores
ORDER BY monetary DESC
LIMIT 25;


-- ------------------------------------------------------------------------------
-- Question 12: Repeat Purchase Rate (% Customers with >1 Order)
-- Concepts: Conditional Subquery Aggregation, Percentage Ratio
-- ------------------------------------------------------------------------------
WITH customer_order_counts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT 
    COUNT(customer_id) AS total_buying_customers,
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    ROUND(
        (COUNT(CASE WHEN total_orders > 1 THEN 1 END)::NUMERIC / COUNT(customer_id)) * 100, 2
    ) AS repeat_purchase_rate_pct
FROM customer_order_counts;


-- ------------------------------------------------------------------------------
-- Question 13: Customer Churn Risk Analysis (No Orders in Last 90 Days)
-- Concepts: Max Date Subquery, Inactivity Calculation, WHERE Filters
-- ------------------------------------------------------------------------------
WITH last_purchase AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        MAX(o.order_date) AS last_order_date,
        SUM(oi.line_total) AS historical_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
)
SELECT 
    customer_id,
    customer_name,
    email,
    last_order_date,
    EXTRACT(DAY FROM (SELECT MAX(order_date) FROM orders) - last_order_date) AS days_since_last_order,
    historical_spend
FROM last_purchase
WHERE (SELECT MAX(order_date) FROM orders) - last_order_date > INTERVAL '90 days'
ORDER BY historical_spend DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Question 14: Average Days Between Purchases for Multi-Order Customers
-- Concepts: LAG() Window Function over Customer Partition, Date Difference
-- ------------------------------------------------------------------------------
WITH order_lags AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prior_order_date
    FROM orders
    WHERE order_status = 'Completed'
),
days_between AS (
    SELECT 
        customer_id,
        EXTRACT(DAY FROM order_date - prior_order_date) AS days_gap
    FROM order_lags
    WHERE prior_order_date IS NOT NULL
)
SELECT 
    ROUND(AVG(days_gap), 1) AS avg_days_between_purchases,
    MIN(days_gap) AS min_days_between,
    MAX(days_gap) AS max_days_between
FROM days_between;


-- ------------------------------------------------------------------------------
-- Question 15: Monthly Cohort Retention Matrix
-- Concepts: DATE_TRUNC Cohort Analysis, Matrix Pivoting with CASE WHEN
-- ------------------------------------------------------------------------------
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        TO_CHAR(MIN(order_date), 'YYYY-MM') AS cohort_month
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
user_activities AS (
    SELECT 
        o.customer_id,
        cc.cohort_month,
        TO_CHAR(o.order_date, 'YYYY-MM') AS activity_month
    FROM orders o
    JOIN customer_cohorts cc ON o.customer_id = cc.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.customer_id, cc.cohort_month, TO_CHAR(o.order_date, 'YYYY-MM')
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN activity_month = cohort_month THEN customer_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN activity_month = TO_CHAR(TO_DATE(cohort_month, 'YYYY-MM') + INTERVAL '1 month', 'YYYY-MM') THEN customer_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN activity_month = TO_CHAR(TO_DATE(cohort_month, 'YYYY-MM') + INTERVAL '2 month', 'YYYY-MM') THEN customer_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN activity_month = TO_CHAR(TO_DATE(cohort_month, 'YYYY-MM') + INTERVAL '3 month', 'YYYY-MM') THEN customer_id END) AS month_3
FROM user_activities
GROUP BY cohort_month
ORDER BY cohort_month
LIMIT 12;


-- ------------------------------------------------------------------------------
-- Question 16: Monthly Customer Acquisition Velocity
-- Concepts: DATE_TRUNC, COUNT OVER (), Cumulative Customer Base Growth
-- ------------------------------------------------------------------------------
WITH monthly_signups AS (
    SELECT 
        TO_CHAR(created_at, 'YYYY-MM') AS signup_month,
        COUNT(customer_id) AS new_customers
    FROM customers
    GROUP BY TO_CHAR(created_at, 'YYYY-MM')
)
SELECT 
    signup_month,
    new_customers,
    SUM(new_customers) OVER (ORDER BY signup_month ROWS UNBOUNDED PRECEDING) AS total_cumulative_customers
FROM monthly_signups
ORDER BY signup_month;


-- ------------------------------------------------------------------------------
-- Question 17: Pareto 80/20 Rule Analysis on Customer Spend
-- Concepts: NTILE(10) Deciles, Cumulative Spend % Share
-- ------------------------------------------------------------------------------
WITH customer_spend AS (
    SELECT 
        c.customer_id,
        SUM(oi.line_total) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id
),
deciles AS (
    SELECT 
        customer_id,
        total_spend,
        NTILE(10) OVER (ORDER BY total_spend DESC) AS spend_decile
    FROM customer_spend
)
SELECT 
    spend_decile,
    COUNT(customer_id) AS customer_count,
    ROUND(SUM(total_spend), 2) AS decile_revenue,
    ROUND((SUM(total_spend) / SUM(SUM(total_spend)) OVER ()) * 100, 2) AS pct_total_revenue
FROM deciles
GROUP BY spend_decile
ORDER BY spend_decile;


-- ------------------------------------------------------------------------------
-- Question 18: Profitability Breakdown by Defined Customer Segment
-- Concepts: GROUP BY customer_segment, Margin & Profit Math
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS total_revenue,
    SUM(oi.quantity * p.unit_cost) AS total_cogs,
    SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost) AS net_profit,
    ROUND(AVG(oi.line_total), 2) AS avg_item_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_segment
ORDER BY net_profit DESC;


-- ==============================================================================
-- DOMAIN 3: PRODUCT PERFORMANCE, CATALOG & INVENTORY
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Question 19: Top 10 Best-Selling Products by Revenue and Quantity
-- Concepts: RANK() Window Function, Multi-table JOIN
-- ------------------------------------------------------------------------------
WITH product_perf AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.line_total) AS total_revenue,
        RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS revenue_rank
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name, c.category_name
)
SELECT 
    revenue_rank,
    product_id,
    product_name,
    category_name,
    units_sold,
    total_revenue
FROM product_perf
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


-- ------------------------------------------------------------------------------
-- Question 20: Underperforming Products with High Inventory Stock
-- Concepts: Dead-stock identification filter (High stock, Low recent sales)
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.stock_quantity,
    p.unit_cost,
    (p.stock_quantity * p.unit_cost) AS tied_up_capital,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.stock_quantity, p.unit_cost
HAVING COALESCE(SUM(oi.quantity), 0) < 50 AND p.stock_quantity > 100
ORDER BY tied_up_capital DESC;


-- ------------------------------------------------------------------------------
-- Question 21: Pareto 80/20 Rule on Product Revenue Concentration
-- Concepts: Cumulative SUM OVER () window calculation for product sales
-- ------------------------------------------------------------------------------
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.line_total) AS product_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name
),
cumulative_sales AS (
    SELECT 
        product_id,
        product_name,
        product_revenue,
        SUM(product_revenue) OVER (ORDER BY product_revenue DESC ROWS UNBOUNDED PRECEDING) AS running_total,
        SUM(product_revenue) OVER () AS grand_total
    FROM product_sales
)
SELECT 
    product_id,
    product_name,
    product_revenue,
    ROUND((running_total / grand_total) * 100, 2) AS cumulative_pct_share
FROM cumulative_sales
WHERE (running_total / grand_total) <= 0.80
ORDER BY product_revenue DESC;


-- ------------------------------------------------------------------------------
-- Question 22: Market Basket Analysis (Products Frequently Bought Together)
-- Concepts: Self-JOIN on order_items table, Product pair counting
-- ------------------------------------------------------------------------------
SELECT 
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
JOIN orders o ON oi1.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- Question 23: Product Reorder Rate (% of Repeat Orders for Same SKU)
-- Concepts: Multi-order product counts, Percentage formula
-- ------------------------------------------------------------------------------
WITH product_customer_orders AS (
    SELECT 
        product_id,
        customer_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY product_id, customer_id
)
SELECT 
    p.product_id,
    p.product_name,
    COUNT(pco.customer_id) AS total_purchasers,
    COUNT(CASE WHEN pco.order_count > 1 THEN 1 END) AS repeat_purchasers,
    ROUND(
        (COUNT(CASE WHEN pco.order_count > 1 THEN 1 END)::NUMERIC / NULLIF(COUNT(pco.customer_id), 0)) * 100, 2
    ) AS reorder_rate_pct
FROM product_customer_orders pco
JOIN products p ON pco.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(pco.customer_id) >= 10
ORDER BY reorder_rate_pct DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- Question 24: Product Stockout Alert (Items Below Reorder Level)
-- Concepts: WHERE filter comparing stock_quantity <= reorder_level
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    s.supplier_name,
    p.stock_quantity,
    p.reorder_level,
    (p.reorder_level - p.stock_quantity) AS recommended_reorder_qty
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
WHERE p.stock_quantity <= p.reorder_level
ORDER BY p.stock_quantity ASC;


-- ------------------------------------------------------------------------------
-- Question 25: Product Return & Cancellation Rate Analysis
-- Concepts: SUM(CASE WHEN), Ratio of returned vs completed orders
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) AS total_orders_placed,
    COUNT(DISTINCT CASE WHEN o.order_status = 'Returned' THEN o.order_id END) AS returned_orders,
    COUNT(DISTINCT CASE WHEN o.order_status = 'Cancelled' THEN o.order_id END) AS cancelled_orders,
    ROUND(
        (COUNT(DISTINCT CASE WHEN o.order_status = 'Returned' THEN o.order_id END)::NUMERIC / COUNT(DISTINCT oi.order_id)) * 100, 2
    ) AS return_rate_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(DISTINCT oi.order_id) >= 20
ORDER BY return_rate_pct DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- Question 26: Category Growth Rate (Comparing First Half vs Second Half Sales)
-- Concepts: Conditional CASE WHEN SUM for semi-annual comparison
-- ------------------------------------------------------------------------------
WITH semi_annual_sales AS (
    SELECT 
        c.category_name,
        SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) <= 6 THEN oi.line_total ELSE 0 END) AS h1_revenue,
        SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) > 6 THEN oi.line_total ELSE 0 END) AS h2_revenue
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.category_name
)
SELECT 
    category_name,
    h1_revenue,
    h2_revenue,
    ROUND(((h2_revenue - h1_revenue) / NULLIF(h1_revenue, 0)) * 100, 2) AS h2_growth_pct
FROM semi_annual_sales
ORDER BY h2_growth_pct DESC;


-- ------------------------------------------------------------------------------
-- Question 27: Price Tier Distribution & Sales Volume
-- Concepts: CASE WHEN Price Bucketing, Aggregation
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN p.unit_price < 50 THEN 'Budget (< $50)'
        WHEN p.unit_price BETWEEN 50 AND 199.99 THEN 'Mid-Range ($50 - $200)'
        WHEN p.unit_price BETWEEN 200 AND 499.99 THEN 'Premium ($200 - $500)'
        ELSE 'Luxury / High-End ($500+)'
    END AS price_tier,
    COUNT(DISTINCT p.product_id) AS total_skus,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY 
    CASE 
        WHEN p.unit_price < 50 THEN 'Budget (< $50)'
        WHEN p.unit_price BETWEEN 50 AND 199.99 THEN 'Mid-Range ($50 - $200)'
        WHEN p.unit_price BETWEEN 200 AND 499.99 THEN 'Premium ($200 - $500)'
        ELSE 'Luxury / High-End ($500+)'
    END
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------------------------
-- Question 28: Inventory Turnover Velocity per Category
-- Concepts: Units Sold vs Total Stocked Inventory Ratio
-- ------------------------------------------------------------------------------
SELECT 
    c.category_name,
    SUM(p.stock_quantity) AS current_stock_on_hand,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.quantity)::NUMERIC / NULLIF(SUM(p.stock_quantity), 0), 2) AS turnover_ratio
FROM categories c
JOIN products p ON c.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY c.category_name
ORDER BY turnover_ratio DESC;


-- ==============================================================================
-- DOMAIN 4: SALES SEASONALITY, TIME-SERIES & TRENDS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Question 29: Peak Order Hour & Day of Week Sales Heatmap
-- Concepts: EXTRACT(DOW/HOUR), Matrix Aggregation
-- ------------------------------------------------------------------------------
SELECT 
    TO_CHAR(o.order_date, 'Day') AS day_of_week,
    EXTRACT(HOUR FROM o.order_date) AS order_hour,
    COUNT(o.order_id) AS total_orders,
    SUM(oi.line_total) AS hourly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'Day'), EXTRACT(DOW FROM o.order_date), EXTRACT(HOUR FROM o.order_date)
ORDER BY total_orders DESC
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Question 30: Weekend vs Weekday Revenue & Order Performance Comparison
-- Concepts: EXTRACT(ISODOW), Conditional CASE WHEN breakdown
-- ------------------------------------------------------------------------------
SELECT 
    CASE WHEN EXTRACT(ISODOW FROM o.order_date) IN (6, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS total_revenue,
    ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY CASE WHEN EXTRACT(ISODOW FROM o.order_date) IN (6, 7) THEN 'Weekend' ELSE 'Weekday' END;


-- ------------------------------------------------------------------------------
-- Question 31: 30-Day Moving Average Revenue Trend vs Actual Daily Revenue
-- Concepts: Window Frame AVG OVER (ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
-- ------------------------------------------------------------------------------
WITH daily_sales AS (
    SELECT 
        DATE(o.order_date) AS sales_date,
        SUM(oi.line_total) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE(o.order_date)
)
SELECT 
    sales_date,
    daily_revenue,
    ROUND(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_30day
FROM daily_sales
ORDER BY sales_date DESC
LIMIT 45;


-- ------------------------------------------------------------------------------
-- Question 32: Consecutive Day Revenue Deltas using LEAD() and LAG()
-- Concepts: Window Functions LEAD() and LAG() for daily velocity comparisons
-- ------------------------------------------------------------------------------
WITH daily_totals AS (
    SELECT 
        DATE(o.order_date) AS sales_date,
        SUM(oi.line_total) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE(o.order_date)
)
SELECT 
    sales_date,
    revenue AS current_day_revenue,
    LAG(revenue) OVER (ORDER BY sales_date) AS prior_day_revenue,
    revenue - LAG(revenue) OVER (ORDER BY sales_date) AS day_over_day_change,
    LEAD(revenue) OVER (ORDER BY sales_date) AS next_day_revenue
FROM daily_totals
ORDER BY sales_date DESC
LIMIT 30;


-- ------------------------------------------------------------------------------
-- Question 33: Month-to-Date (MTD) Revenue Trajectory vs Prior Month
-- Concepts: Window functions, Cumulative SUM over current vs prior month
-- ------------------------------------------------------------------------------
WITH current_month_sales AS (
    SELECT 
        EXTRACT(DAY FROM o.order_date) AS day_of_month,
        SUM(oi.line_total) AS daily_rev
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
      AND o.order_date >= '2026-07-01' AND o.order_date < '2026-08-01'
    GROUP BY EXTRACT(DAY FROM o.order_date)
)
SELECT 
    day_of_month,
    daily_rev,
    SUM(daily_rev) OVER (ORDER BY day_of_month) AS mtd_cumulative_revenue
FROM current_month_sales
ORDER BY day_of_month;


-- ------------------------------------------------------------------------------
-- Question 34: Quarterly Revenue Velocity Trends across Multiple Years
-- Concepts: Multi-year pivot using CASE WHEN aggregations
-- ------------------------------------------------------------------------------
SELECT 
    EXTRACT(YEAR FROM o.order_date) AS sales_year,
    SUM(CASE WHEN EXTRACT(QUARTER FROM o.order_date) = 1 THEN oi.line_total ELSE 0 END) AS q1_revenue,
    SUM(CASE WHEN EXTRACT(QUARTER FROM o.order_date) = 2 THEN oi.line_total ELSE 0 END) AS q2_revenue,
    SUM(CASE WHEN EXTRACT(QUARTER FROM o.order_date) = 3 THEN oi.line_total ELSE 0 END) AS q3_revenue,
    SUM(CASE WHEN EXTRACT(QUARTER FROM o.order_date) = 4 THEN oi.line_total ELSE 0 END) AS q4_revenue,
    SUM(oi.line_total) AS annual_total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY EXTRACT(YEAR FROM o.order_date)
ORDER BY sales_year;


-- ------------------------------------------------------------------------------
-- Question 35: Holiday/Promotional Period Revenue Surge Analysis
-- Concepts: Date range filter comparing promo dates to baseline average
-- ------------------------------------------------------------------------------
SELECT 
    DATE(o.order_date) AS sales_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS promo_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
  AND (
      (o.order_date >= '2024-11-20' AND o.order_date <= '2024-11-30') OR  -- Black Friday
      (o.order_date >= '2025-11-20' AND o.order_date <= '2025-11-30')
  )
GROUP BY DATE(o.order_date)
ORDER BY promo_revenue DESC;


-- ------------------------------------------------------------------------------
-- Question 36: Average Order Count & Revenue Matrix by Day of Week
-- Concepts: TO_CHAR(date, 'Day') grouping with Average Order Value
-- ------------------------------------------------------------------------------
SELECT 
    TO_CHAR(o.order_date, 'Day') AS day_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS total_revenue,
    ROUND(AVG(oi.line_total), 2) AS avg_item_line_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'Day'), EXTRACT(DOW FROM o.order_date)
ORDER BY EXTRACT(DOW FROM o.order_date);


-- ==============================================================================
-- DOMAIN 5: PRICING, DISCOUNTS & PROFITABILITY
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Question 37: Total Discounts Granted & Discount % of Sales by Category
-- Concepts: SUM(discount_amount), Discount Share Calculation
-- ------------------------------------------------------------------------------
SELECT 
    c.category_name,
    SUM(oi.quantity * oi.unit_price) AS gross_sales_before_discount,
    SUM(oi.discount_amount) AS total_discounts_given,
    SUM(oi.line_total) AS net_revenue_after_discount,
    ROUND(
        (SUM(oi.discount_amount) / NULLIF(SUM(oi.quantity * oi.unit_price), 0)) * 100, 2
    ) AS discount_effective_pct
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.category_name
ORDER BY total_discounts_given DESC;


-- ------------------------------------------------------------------------------
-- Question 38: Discount Bucket Impact on Units & Average Order Size
-- Concepts: CASE WHEN Discount Bucketing, Aggregation per Bucket
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN oi.discount_amount = 0 THEN '0% No Discount'
        WHEN (oi.discount_amount / (oi.quantity * oi.unit_price)) <= 0.10 THEN '1% - 10% Discount'
        WHEN (oi.discount_amount / (oi.quantity * oi.unit_price)) <= 0.20 THEN '11% - 20% Discount'
        ELSE '20%+ High Discount'
    END AS discount_tier,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS tier_net_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY 
    CASE 
        WHEN oi.discount_amount = 0 THEN '0% No Discount'
        WHEN (oi.discount_amount / (oi.quantity * oi.unit_price)) <= 0.10 THEN '1% - 10% Discount'
        WHEN (oi.discount_amount / (oi.quantity * oi.unit_price)) <= 0.20 THEN '11% - 20% Discount'
        ELSE '20%+ High Discount'
    END
ORDER BY tier_net_revenue DESC;


-- ------------------------------------------------------------------------------
-- Question 39: Gross Profit Margin & Revenue Performance by Vendor/Supplier
-- Concepts: Vendor rating evaluation against gross profit margin
-- ------------------------------------------------------------------------------
SELECT 
    s.supplier_name,
    s.rating AS supplier_rating,
    COUNT(DISTINCT p.product_id) AS catalog_skus,
    SUM(oi.line_total) AS total_vendor_revenue,
    SUM(oi.quantity * p.unit_cost) AS total_vendor_cogs,
    SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost) AS gross_profit,
    ROUND(
        ((SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost)) / NULLIF(SUM(oi.line_total), 0)) * 100, 2
    ) AS supplier_margin_pct
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY s.supplier_id, s.supplier_name, s.rating
ORDER BY gross_profit DESC;


-- ------------------------------------------------------------------------------
-- Question 40: High-Discount Low-Margin Anomaly Alert Query
-- Concepts: Filter orders with high discount (>15%) but low margin (<10%)
-- ------------------------------------------------------------------------------
WITH order_margins AS (
    SELECT 
        o.order_id,
        c.email AS customer_email,
        SUM(oi.discount_amount) AS total_discount,
        SUM(oi.line_total) AS order_revenue,
        SUM(oi.quantity * p.unit_cost) AS order_cogs,
        (SUM(oi.line_total) - SUM(oi.quantity * p.unit_cost)) AS order_profit
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, c.email
)
SELECT 
    order_id,
    customer_email,
    total_discount,
    order_revenue,
    order_profit,
    ROUND((order_profit / NULLIF(order_revenue, 0)) * 100, 2) AS profit_margin_pct
FROM order_margins
WHERE order_revenue > 0 
  AND (order_profit / order_revenue) < 0.10
  AND total_discount > 20.00
ORDER BY order_profit ASC;


-- ------------------------------------------------------------------------------
-- Question 41: Revenue Impact of Free Shipping vs Paid Shipping Orders
-- Concepts: CASE WHEN shipping_cost = 0, Comparative average basket size
-- ------------------------------------------------------------------------------
SELECT 
    CASE WHEN o.shipping_cost = 0 THEN 'Free Shipping' ELSE 'Paid Shipping' END AS shipping_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS total_revenue,
    ROUND(AVG(oi.line_total), 2) AS avg_item_line_spend
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY CASE WHEN o.shipping_cost = 0 THEN 'Free Shipping' ELSE 'Paid Shipping' END;


-- ------------------------------------------------------------------------------
-- Question 42: Financial Loss from Returned and Cancelled Orders
-- Concepts: SUM(CASE WHEN order_status IN ('Cancelled', 'Returned'))
-- ------------------------------------------------------------------------------
SELECT 
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.line_total) AS lost_gross_revenue,
    SUM(o.shipping_cost) AS lost_shipping_cost,
    SUM(oi.line_total) + SUM(o.shipping_cost) AS total_financial_impact
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status IN ('Cancelled', 'Returned')
GROUP BY o.order_status;


-- ------------------------------------------------------------------------------
-- Question 43: Average Selling Price (ASP) Trajectory Over Time
-- Concepts: Total Net Revenue / Total Quantity Sold per Month
-- ------------------------------------------------------------------------------
SELECT 
    TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue,
    ROUND(SUM(oi.line_total) / NULLIF(SUM(oi.quantity), 0), 2) AS average_selling_price_asp
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY sales_month;


-- ==============================================================================
-- DOMAIN 6: OPERATIONS, LOGISTICS & PAYMENT GATEWAYS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Question 44: Payment Gateway Market Share & Failure/Refund Rate
-- Concepts: JOIN payments table, Status percentage breakdown
-- ------------------------------------------------------------------------------
SELECT 
    payment_method,
    COUNT(payment_id) AS total_transactions,
    SUM(amount_paid) AS processed_volume,
    COUNT(CASE WHEN payment_status = 'Completed' THEN 1 END) AS successful_txns,
    COUNT(CASE WHEN payment_status = 'Failed' THEN 1 END) AS failed_txns,
    COUNT(CASE WHEN payment_status = 'Refunded' THEN 1 END) AS refunded_txns,
    ROUND(
        (COUNT(CASE WHEN payment_status = 'Failed' THEN 1 END)::NUMERIC / COUNT(payment_id)) * 100, 2
    ) AS failure_rate_pct
FROM payments
GROUP BY payment_method
ORDER BY processed_volume DESC;


-- ------------------------------------------------------------------------------
-- Question 45: Regional Shipping Cost Burden by Destination State
-- Concepts: AVG(shipping_cost), SUM(shipping_cost) per state
-- ------------------------------------------------------------------------------
SELECT 
    shipping_state,
    COUNT(order_id) AS total_shipments,
    SUM(shipping_cost) AS total_shipping_revenue,
    ROUND(AVG(shipping_cost), 2) AS avg_shipping_cost_per_order
FROM orders
WHERE order_status IN ('Completed', 'Shipped')
GROUP BY shipping_state
ORDER BY total_shipping_revenue DESC;


-- ------------------------------------------------------------------------------
-- Question 46: Order Fulfillment Status Distribution Split
-- Concepts: COUNT(order_id) OVER () Percentage Share calculation
-- ------------------------------------------------------------------------------
SELECT 
    order_status,
    COUNT(order_id) AS status_count,
    ROUND((COUNT(order_id)::NUMERIC / (SELECT COUNT(*) FROM orders)) * 100, 2) AS status_pct_share
FROM orders
GROUP BY order_status
ORDER BY status_count DESC;


-- ------------------------------------------------------------------------------
-- Question 47: Supplier Cancellation & Return Rate Audit
-- Concepts: Joining suppliers to order status outcomes
-- ------------------------------------------------------------------------------
SELECT 
    s.supplier_name,
    COUNT(DISTINCT o.order_id) AS total_orders_handled,
    COUNT(DISTINCT CASE WHEN o.order_status IN ('Cancelled', 'Returned') THEN o.order_id END) AS failed_orders,
    ROUND(
        (COUNT(DISTINCT CASE WHEN o.order_status IN ('Cancelled', 'Returned') THEN o.order_id END)::NUMERIC / COUNT(DISTINCT o.order_id)) * 100, 2
    ) AS supplier_failure_rate_pct
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY s.supplier_id, s.supplier_name
ORDER BY supplier_failure_rate_pct DESC;


-- ------------------------------------------------------------------------------
-- Question 48: Customer Preferred Payment Method vs Average Lifetime Spend
-- Concepts: Mode Payment Method per Customer, Average Spend
-- ------------------------------------------------------------------------------
WITH customer_payments AS (
    SELECT 
        o.customer_id,
        p.payment_method,
        SUM(p.amount_paid) AS total_paid
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE p.payment_status = 'Completed'
    GROUP BY o.customer_id, p.payment_method
)
SELECT 
    payment_method,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(AVG(total_paid), 2) AS avg_customer_spend
FROM customer_payments
GROUP BY payment_method
ORDER BY avg_customer_spend DESC;


-- ------------------------------------------------------------------------------
-- Question 49: FULL OUTER JOIN Integrity Audit (Inactive Customers & Unlinked Orders)
-- Concepts: FULL OUTER JOIN between Customers and Orders
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id AS customer_table_id,
    o.order_id AS order_table_id,
    CASE 
        WHEN o.order_id IS NULL THEN 'Registered Customer - No Orders Placed'
        WHEN c.customer_id IS NULL THEN 'Orphan Order - Missing Customer Profile'
        ELSE 'Active Customer Order'
    END AS audit_status
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL OR c.customer_id IS NULL
LIMIT 20;


-- ------------------------------------------------------------------------------
-- Question 50: Executive Master Summary Dashboard Query (All KPIs in Single Row)
-- Concepts: Scalar subqueries combining revenue, customer count, products & profit
-- ------------------------------------------------------------------------------
SELECT 
    (SELECT COUNT(*) FROM customers) AS total_registered_customers,
    (SELECT COUNT(*) FROM products WHERE is_active = TRUE) AS active_skus,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'Completed') AS total_completed_orders,
    (SELECT SUM(line_total) FROM order_items oi JOIN orders o ON oi.order_id = o.order_id WHERE o.order_status = 'Completed') AS gross_platform_revenue,
    (SELECT ROUND(SUM(line_total) / COUNT(DISTINCT o.order_id), 2) FROM order_items oi JOIN orders o ON oi.order_id = o.order_id WHERE o.order_status = 'Completed') AS platform_aov,
    (SELECT SUM(line_total) - SUM(quantity * unit_cost) FROM order_items oi JOIN products p ON oi.product_id = p.product_id JOIN orders o ON oi.order_id = o.order_id WHERE o.order_status = 'Completed') AS total_net_profit;
