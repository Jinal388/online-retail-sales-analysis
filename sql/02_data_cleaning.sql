-- Clean table: proper types, duplicates and zero-price rows removed, flags added
DROP TABLE IF EXISTS retail.transactions_clean;

CREATE TABLE retail.transactions_clean AS
WITH typed AS (
    -- Step 1: convert text to real types, drop zero/negative prices, remove exact duplicates
    SELECT DISTINCT
        invoice_no,
        stock_code,
        NULLIF(TRIM(description), '') AS description,
        quantity::int AS quantity,
        TO_TIMESTAMP(invoice_date, 'DD-MM-YYYY HH24:MI')::timestamp AS invoice_date,
        unit_price::numeric(10,2) AS unit_price,
        NULLIF(customer_id, '')::int AS customer_id,
        TRIM(country) AS country
    FROM retail.raw_transactions
    WHERE unit_price::numeric > 0
)
-- Step 2: add flags and revenue column
SELECT
    ROW_NUMBER() OVER (ORDER BY invoice_date, invoice_no, stock_code) AS row_id,
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    (invoice_no LIKE 'C%') AS is_cancelled,   -- cancellation invoice
    (stock_code ~ '^[0-9]{5}') AS is_product,     -- false for POSTAGE, DOT, etc.
    (customer_id IS NOT NULL) AS has_customer,   -- usable for customer analysis
    quantity * unit_price AS line_total      -- negative for cancellations
FROM typed;

ALTER TABLE retail.transactions_clean ADD PRIMARY KEY (row_id);

-- Overall counts and date range (expect end of data around 9 Dec 2011)
SELECT COUNT(*) AS clean_rows,
       MIN(invoice_date) AS first_date,
       MAX(invoice_date) AS last_date
FROM retail.transactions_clean;

-- Negative quantities that are still not cancellations after cleaning
SELECT COUNT(*) AS neg_qty_not_cancel_left
FROM retail.transactions_clean
WHERE quantity < 0 AND NOT is_cancelled;

-- Quick breakdown of flags
SELECT is_cancelled, is_product, has_customer, COUNT(*) AS n
FROM retail.transactions_clean
GROUP BY 1, 2, 3 ORDER BY n DESC;


