# 20 Senior Data Analyst SQL Interview Questions & Answers

This document contains 20 production-grade SQL interview questions with comprehensive answers based directly on the **E-Commerce Sales Analytics** project. Tailored for Senior Data Analyst / Lead BI Engineer technical screens at top-tier tech companies (e.g., Amazon, Google, Microsoft).

---

## 1. SQL Execution Order & Mechanics

### Q1: What is the logical execution order of a SQL query, and why does `WHERE` come before `GROUP BY` while `HAVING` comes after?
**Answer:**
The logical execution order of an ANSI SQL query is:
1. `FROM` & `JOIN` (Identify source tables and evaluate join conditions)
2. `WHERE` (Filter individual row records before grouping)
3. `GROUP BY` (Aggregate rows into summary buckets)
4. `HAVING` (Filter aggregated group rows)
5. `SELECT` (Compute expressions, aliases, and window functions)
6. `DISTINCT` (Eliminate duplicate result rows)
7. `ORDER BY` (Sort final output)
8. `LIMIT` / `OFFSET` (Restrict row count)

**Key Difference:**
`WHERE` filters **individual rows** before aggregations are computed. Therefore, aggregate functions like `SUM()` or `COUNT()` cannot be evaluated inside `WHERE`. `HAVING` filters **grouped summary data** after aggregations have been calculated by `GROUP BY`.

---

### Q2: How did you compute Month-over-Month (MoM) revenue growth in this project, and how does `LAG()` work internally?
**Answer:**
We calculated MoM revenue growth using a Common Table Expression (CTE) combined with the `LAG()` window function:

```sql
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
    ROUND(((revenue - LAG(revenue, 1) OVER (ORDER BY sales_month)) / 
        NULLIF(LAG(revenue, 1) OVER (ORDER BY sales_month), 0)) * 100, 2) AS mom_growth_pct
FROM monthly_revenue;
```

**Internal Mechanism:**
`LAG(revenue, 1)` looks back 1 row relative to the current row within the partition sorted by `sales_month`. `NULLIF()` prevents division-by-zero errors for the initial row where `LAG()` returns `NULL`.

---

### Q3: What is the difference between `RANK()`, `DENSE_RANK()`, and `ROW_NUMBER()`? When would you use each?
**Answer:**
All three are window ranking functions, but handle ties differently:
- **`ROW_NUMBER()`**: Assigns a unique sequential integer (1, 2, 3, 4) to each row, ignoring ties.
- **`RANK()`**: Assigns identical ranks to tied rows, but **skips subsequent ranks** (e.g., 1, 2, 2, 4).
- **`DENSE_RANK()`**: Assigns identical ranks to tied rows **without skipping ranks** (e.g., 1, 2, 2, 3).

**Use Cases in Project:**
- We used **`DENSE_RANK()`** in Customer Spend Leaderboard (Q9) so tied customers share top ranks without skipping numbers.
- We used **`ROW_NUMBER()`** in Data Cleaning (03_data_cleaning.sql) for deduplicating customer emails.

---

### Q4: Explain how you calculated Customer Lifetime Value (CLV) and handling customer churn in SQL.
**Answer:**
CLV was computed by joining customer registration dates with historical aggregated completed spending:

```sql
SELECT 
    c.customer_id,
    EXTRACT(YEAR FROM c.created_at) AS signup_year,
    COALESCE(SUM(oi.line_total), 0) AS lifetime_spend
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'Completed'
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, EXTRACT(YEAR FROM c.created_at);
```

**Churn Definition:** Customers were tagged as "Churned Risk" if their `MAX(order_date)` was greater than 90 days prior to the current max dataset timestamp, helping marketing target re-engagement campaigns.

---

### Q5: How did you implement RFM (Recency, Frequency, Monetary) segmentation using `NTILE()`?
**Answer:**
We segmented customers into 5 equal quintiles using `NTILE(5)` over three dimensions:
- **Recency (R)**: Days since last order (`NTILE(5) OVER (ORDER BY recency_days ASC)`).
- **Frequency (F)**: Total completed orders (`NTILE(5) OVER (ORDER BY frequency DESC)`).
- **Monetary (M)**: Total spend (`NTILE(5) OVER (ORDER BY monetary DESC)`).

We concatenated these 3 scores (e.g., '555' for Champions, '111' for Hibernating) to trigger targeted retention strategies.

---

### Q6: What is a Covering Index, and how did it improve query execution time in your project?
**Answer:**
A **Covering Index** is a secondary index that includes all columns requested by a query (either in the indexed key or via the `INCLUDE` clause). This allows the database optimizer to satisfy the query entirely from the index tree using an **Index Only Scan**, eliminating costly random I/O heap fetches.

In `08_indexes.sql`:
```sql
CREATE INDEX idx_order_items_product_covering 
ON order_items (product_id) 
INCLUDE (quantity, line_total);
```
**Result:** Reduced Product Performance query execution time from 112.0 ms to 8.4 ms (13.3x speedup).

---

### Q7: Explain the Pareto 80/20 Rule SQL implementation in your project.
**Answer:**
We calculated the cumulative revenue share using a windowed `SUM()` over ordered product sales:

```sql
WITH product_sales AS (
    SELECT p.product_id, p.product_name, SUM(oi.line_total) AS product_revenue
    FROM products p JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.product_name
),
cumulative AS (
    SELECT product_id, product_name, product_revenue,
        SUM(product_revenue) OVER (ORDER BY product_revenue DESC ROWS UNBOUNDED PRECEDING) AS running_total,
        SUM(product_revenue) OVER () AS grand_total
    FROM product_sales
)
SELECT product_id, product_name, product_revenue,
    ROUND((running_total / grand_total) * 100, 2) AS cumulative_pct_share
FROM cumulative WHERE (running_total / grand_total) <= 0.80;
```

---

### Q8: What is Market Basket Analysis, and how do you write a self-join in SQL to discover cross-selling opportunities?
**Answer:**
Market Basket Analysis finds product pairs frequently purchased in the same order. We implemented this by self-joining `order_items` on `order_id`:

```sql
SELECT 
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
WHERE oi1.order_id IN (SELECT order_id FROM orders WHERE order_status = 'Completed')
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC;
```
*Note:* The condition `oi1.product_id < oi2.product_id` prevents duplicate pairs (A, B and B, A) and self-matching (A, A).

---

### Q9: How do you handle missing values, duplicates, and anomalies in a data cleaning pipeline?
**Answer:**
1. **Missing Data**: Handled via `COALESCE()` and defaults (`phone = '+1-555-000-0000'`).
2. **Duplicates**: Identified via `ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at)` and removed with `DELETE`.
3. **Anomalies**: Audit triggers log order dates occurring prior to customer sign-up dates into `audit_logs` and auto-correct timestamps.

---

### Q10: What is the difference between `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, and `FULL OUTER JOIN`?
**Answer:**
- **`INNER JOIN`**: Returns only matching rows in both tables.
- **`LEFT JOIN`**: Returns all rows from the left table and matching rows from the right table (NULL if no match).
- **`RIGHT JOIN`**: Returns all rows from the right table and matching rows from the left table.
- **`FULL OUTER JOIN`**: Returns all rows when there is a match in either table. Used in Q49 to audit orphaned orders or inactive customers.

---

### Q11: What are Window Frames (`ROWS BETWEEN ...`), and how are they used for Moving Averages?
**Answer:**
Window frames define a subset of rows within a partition relative to the current row.
In Q4 & Q31: `AVG(daily_revenue) OVER (ORDER BY sales_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` calculates a 7-day rolling average revenue.

---

### Q12: How do CTEs (`WITH` clauses) compare to Subqueries and Temporary Tables?
**Answer:**
- **CTE**: Improves readability and modularity. Can be recursive. In PostgreSQL, modern query planners inline non-recursive CTEs without performance overhead.
- **Subquery**: Inline query inside `FROM` or `WHERE`. Can become hard to read when deeply nested.
- **Temporary Table**: Materialized table stored on disk/temp storage. Useful when intermediate results must be indexed or referenced multiple times across long transactions.

---

### Q13: How did you implement database ACID transaction safety in stored procedures?
**Answer:**
In `sp_process_new_order`, we wrapped multi-table inserts/updates inside an atomic PL/pgSQL block. If product stock is insufficient (`v_stock < p_quantity`), an exception is raised (`RAISE EXCEPTION`), triggering an automatic ROLLBACK of all pending inserts across `orders`, `order_items`, `payments`, and `products`.

---

### Q14: What is the function of a Database Trigger, and what are its performance implications?
**Answer:**
A trigger automatically executes a PL/pgSQL function in response to `INSERT`, `UPDATE`, or `DELETE` events.
**Implications**: `BEFORE` / `AFTER EACH ROW` triggers add overhead to Write (DML) operations. We limited triggers to critical business logic: stock recovery on order cancellation, audit logging, and price validation.

---

### Q15: How do you identify slow-performing queries and optimize them?
**Answer:**
1. Use `EXPLAIN ANALYZE` to inspect query execution plans, identifying Sequential Scans, high cost steps, and disk sorts.
2. Add appropriate B-Tree, Composite, or Partial Indexes.
3. Rewrite queries to eliminate non-sargable functions in `WHERE` clauses (e.g., replace `WHERE YEAR(date) = 2025` with `WHERE date >= '2025-01-01' AND date < '2026-01-01'`).

---

### Q16: What is a Non-Sargable Query operator, and how do you fix it?
**Answer:**
SARGable stands for "Search Argument Able". A query is non-sargable when a function wraps an indexed column (e.g., `WHERE LOWER(email) = 'user@example.com'`), forcing the engine to evaluate the function for every row via a Sequential Scan.
**Fix**: Create a functional index (`CREATE INDEX idx_lower_email ON customers (LOWER(email));`).

---

### Q17: How do you calculate Customer Retention Matrix across Monthly Sign-up Cohorts?
**Answer:**
We extract the initial cohort month for each customer, then count unique active customers placing orders in subsequent relative months (`month_0`, `month_1`, `month_2`, `month_3`) using conditional `CASE WHEN` aggregations (Q15).

---

### Q18: How do you handle NULL values in aggregate functions like `SUM()`, `AVG()`, and `COUNT()`?
**Answer:**
- `COUNT(*)` counts all rows including NULLs.
- `COUNT(column)` ignores NULL values.
- `SUM()` and `AVG()` ignore NULL values. If all values are NULL, `SUM()` returns `NULL` (handled via `COALESCE(SUM(val), 0)`).

---

### Q19: How do you write a query to detect Underperforming High-Stock Products?
**Answer:**
We filter products where `stock_quantity > 100` but sales quantity in `order_items` over the last 90 days is `< 50` using `HAVING COALESCE(SUM(oi.quantity), 0) < 50` (Q20), identifying tied-up capital.

---

### Q20: How does this SQL analytics project translate into direct business value for an e-commerce platform?
**Answer:**
1. **Revenue Growth**: Identified top 20% products driving 80% sales for targeted ad spend.
2. **Inventory Cost Reduction**: Flagged dead-stock items to clear warehouse space.
3. **Customer Retention**: RFM segmentation enabled targeted campaigns for at-risk customers, improving repeat purchase rates.
4. **Fulfillment Efficiency**: Regional shipping cost analysis revealed state shipping cost burdens.
