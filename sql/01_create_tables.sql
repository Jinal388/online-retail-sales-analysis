-- Create a separate schema to keep project tables organised
CREATE SCHEMA IF NOT EXISTS retail;

-- Drop the old staging table so the script can be rerun cleanly
DROP TABLE IF EXISTS retail.raw_transactions;

-- Staging table: every column is TEXT so the CSV loads without errors.
-- Data types are fixed later, in the cleaning step
CREATE TABLE retail.raw_transactions (
    invoice_no TEXT,
    stock_code TEXT,
    description TEXT,
    quantity TEXT,
    invoice_date TEXT,
    unit_price TEXT,
    customer_id TEXT,
    country TEXT
);

-- Load the CSV into the staging table (skips the header row)
COPY retail.raw_transactions
FROM 'D:/Data Analysis/online-retail-sales-analysis/data/raw/online_retail_clean.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

-- Check the load worked (expected: ~541,909 rows)
SELECT COUNT(*) AS row_count FROM retail.raw_transactions;


-- 1. Total rows (baseline to compare after cleaning)
SELECT COUNT(*) AS total_rows FROM retail.raw_transactions;

-- 2. Missing customer IDs and descriptions
SELECT
  COUNT(*) FILTER (WHERE customer_id IS NULL OR customer_id = '') AS no_customer,
  COUNT(*) FILTER (WHERE description IS NULL OR description = '') AS no_description
FROM retail.raw_transactions;

-- 3. Cancelled invoices (start with 'C')
SELECT COUNT(*) AS cancelled_rows
FROM retail.raw_transactions WHERE invoice_no LIKE 'C%';

-- 4. Zero or negative prices (adjustments, not real sales)
SELECT COUNT(*) AS bad_price_rows
FROM retail.raw_transactions WHERE unit_price::numeric <= 0;

-- 5. Negative quantities that are not cancellations (write-offs, damages)
SELECT COUNT(*) AS neg_qty_not_cancel
FROM retail.raw_transactions
WHERE quantity::int < 0 AND invoice_no NOT LIKE 'C%';

-- 6. Non-product codes (POSTAGE, DOT, BANK CHARGES, etc.)
SELECT stock_code, COUNT(*) AS n
FROM retail.raw_transactions
WHERE stock_code !~ '^[0-9]{5}'
GROUP BY stock_code ORDER BY n DESC;

-- 7. Exact duplicate rows
SELECT COUNT(*) AS duplicate_rows FROM (
  SELECT 1 FROM retail.raw_transactions
  GROUP BY invoice_no, stock_code, description, quantity,
           invoice_date, unit_price, customer_id, country
  HAVING COUNT(*) > 1
) d;