-- Q1a. Net revenue by month (Dec 2011 is partial, so flag it in the dashboard)
SELECT
    DATE_TRUNC('month', invoice_date)::date AS month,
    ROUND(SUM(line_total) FILTER (WHERE NOT is_cancelled), 2) AS gross_revenue,
    ROUND(SUM(line_total) FILTER (WHERE is_cancelled), 2) AS cancelled_revenue,
    ROUND(SUM(line_total), 2) AS net_revenue,
    COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancelled) AS orders
FROM retail.transactions_clean
GROUP BY 1
ORDER BY 1;

-- Q1b. Net revenue by country, with share of total
SELECT
    country,
    ROUND(SUM(line_total), 2) AS net_revenue,
    ROUND(100 * SUM(line_total) / SUM(SUM(line_total)) OVER (), 2) AS pct_of_total,
    COUNT(DISTINCT invoice_no) FILTER (WHERE NOT is_cancelled) AS orders
FROM retail.transactions_clean
GROUP BY country
ORDER BY net_revenue DESC;

-- Q1c. Top 15 products by net revenue (real products only)
SELECT
    stock_code,
    MAX(description) AS description,
    SUM(quantity) AS net_units,
    ROUND(SUM(line_total), 2) AS net_revenue
FROM retail.transactions_clean
WHERE is_product
GROUP BY stock_code
ORDER BY net_revenue DESC
LIMIT 15;

-- Largest cancellations: look for a few giant entries
SELECT invoice_no, invoice_date::date AS day, stock_code, description,
       quantity, line_total, customer_id
FROM retail.transactions_clean
WHERE is_cancelled
ORDER BY line_total ASC
LIMIT 5;


SELECT invoice_no, invoice_date, stock_code, quantity, line_total, customer_id, is_cancelled
FROM retail.transactions_clean
WHERE ABS(quantity) >= 50000
ORDER BY stock_code, invoice_date;

-- Flag the two giant order/cancel pairs as data-entry errors
ALTER TABLE retail.transactions_clean ADD COLUMN is_entry_error boolean DEFAULT false;
UPDATE retail.transactions_clean SET is_entry_error = true WHERE ABS(quantity) >= 50000;

-- Q2 (revised). Cancellations by country, real products only, entry errors excluded.
-- cancel_rate_pct = cancelled invoices / all invoices (sales + cancellations)
SELECT
    country,
    COUNT(DISTINCT invoice_no) FILTER (WHERE is_cancelled)   AS cancelled_orders,
    COUNT(DISTINCT invoice_no)                               AS total_orders,
    ROUND(100.0 * COUNT(DISTINCT invoice_no) FILTER (WHERE is_cancelled)
          / COUNT(DISTINCT invoice_no), 2)                   AS cancel_rate_pct,
    ROUND(-SUM(line_total) FILTER (WHERE is_cancelled), 2)   AS revenue_lost
FROM retail.transactions_clean
WHERE is_product AND NOT is_entry_error
GROUP BY country
HAVING COUNT(DISTINCT invoice_no) >= 30      -- ignore countries with too few orders for a reliable rate
ORDER BY cancelled_orders DESC;

-- Q3 (revised). Same filters, products with at least 500 units sold
SELECT
    stock_code,
    MAX(description)                                          AS description,
    SUM(quantity) FILTER (WHERE NOT is_cancelled)             AS units_sold,
    SUM(-quantity) FILTER (WHERE is_cancelled)                AS units_cancelled,
    ROUND(100.0 * SUM(-quantity) FILTER (WHERE is_cancelled)
          / NULLIF(SUM(quantity) FILTER (WHERE NOT is_cancelled), 0), 2) AS cancel_rate_pct,
    ROUND(-SUM(line_total) FILTER (WHERE is_cancelled), 2)    AS revenue_lost
FROM retail.transactions_clean
WHERE is_product AND NOT is_entry_error
GROUP BY stock_code
HAVING SUM(quantity) FILTER (WHERE NOT is_cancelled) >= 500
ORDER BY revenue_lost DESC NULLS LAST
LIMIT 15;


-- Q4. Country scorecard: revenue, growth and cancellations
WITH base AS (
    SELECT
        country, customer_id, invoice_no, line_total, is_cancelled,
        CASE WHEN invoice_date < '2011-06-01' THEN 'H1'   -- Dec 2010 to May 2011
             ELSE 'H2'                                    -- Jun to Nov 2011
        END AS half
    FROM retail.transactions_clean
    WHERE NOT is_entry_error
      AND invoice_date < '2011-12-01'                     -- exclude partial Dec 2011
)
SELECT
    country,
    ROUND(SUM(line_total), 0)                                         AS net_revenue,
    ROUND(SUM(line_total) FILTER (WHERE half = 'H1'), 0)              AS rev_h1,
    ROUND(SUM(line_total) FILTER (WHERE half = 'H2'), 0)              AS rev_h2,
    ROUND(100.0 * (SUM(line_total) FILTER (WHERE half = 'H2')
          / NULLIF(SUM(line_total) FILTER (WHERE half = 'H1'), 0) - 1), 1) AS rev_growth_pct,
    COUNT(DISTINCT customer_id) FILTER (WHERE half = 'H1')            AS customers_h1,
    COUNT(DISTINCT customer_id) FILTER (WHERE half = 'H2')            AS customers_h2,
    COUNT(DISTINCT customer_id)                                       AS customers_total,
    ROUND(100.0 * COUNT(DISTINCT invoice_no) FILTER (WHERE is_cancelled)
          / COUNT(DISTINCT invoice_no), 1)                            AS cancel_rate_pct
FROM base
GROUP BY country
HAVING COUNT(DISTINCT customer_id) >= 5      -- too few customers makes growth rates meaningless
ORDER BY net_revenue DESC;