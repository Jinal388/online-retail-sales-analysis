# Cleaning Decisions

Source: UCI Online Retail dataset (Online_Retail.xlsx), saved as CSV and loaded into PostgreSQL.
Raw table: `retail.raw_transactions` (all TEXT columns). Clean table: `retail.transactions_clean`.

## Data profile (raw)

| Check | Rows |
|---|---|
| Total rows | 541,909 |
| Missing CustomerID | 135,080 |
| Missing description | 1,454 |
| Cancelled invoices (InvoiceNo starts with "C") | 9,288 |
| Zero or negative unit price | 2,517 |
| Negative quantity, not a cancellation | 1,336 |
| Duplicated row groups | 4,879 |

Date range: 1 Dec 2010 to 9 Dec 2011. Dates in the CSV are DD-MM-YYYY HH:MM.

## Decisions

| Issue | Decision | Reason |
|---|---|---|
| Text columns | Loaded everything as TEXT, cast types in the cleaning step | Avoids load failures on messy values |
| Zero or negative price (2,517) | Dropped | Adjustments and bad-debt entries, not sales |
| Negative quantity, not a cancellation (1,336) | No separate rule needed | All were removed by the price filter (0 left after cleaning) |
| Exact duplicates | Removed with DISTINCT | Identical in every column. Judgment call, since some could be genuine repeat scans |
| Missing CustomerID (~132.6K rows after cleaning) | Kept, left NULL, flagged `has_customer = false` | Valid for revenue analysis, excluded from customer metrics (repeat buyers, revenue per customer) |
| Missing description | Empty text converted to NULL | Mostly adjustment rows |
| Cancellations (~9.25K rows) | Kept, flagged `is_cancelled` | Needed for CEO cancellation questions and gross vs net revenue |
| Non-product codes (~2.96K rows: POSTAGE, DOT, MANUAL, AMAZONFEE, etc.) | Kept, flagged `is_product = false` | Excluded from product and cancellation metrics, but still part of net revenue totals |
| Entry errors | Flagged `is_entry_error` where ABS(quantity) >= 50,000 | See below |
| Partial month | Dec 2011 (data ends 9 Dec) not compared with full months | Would look like a false drop |

## Entry errors

Two line items were sold and then cancelled in full:
- Paper Craft, Little Birdie (23843): 80,995 units, about £168K, 9 Dec 2011
- Medium Ceramic Top Storage Jar (23166): 74,215 units, about £77K, 18 Jan 2011

Treated as data-entry errors. They net to zero, so net revenue is unaffected, but they inflated gross revenue, cancelled revenue and cancellation rates. They are excluded from gross, cancellation and rate metrics.

TODO: confirm the confirmation query returns the expected 4 rows (2 sale and cancel pairs).

## Result

534,129 clean rows (7,780 removed: 2,517 zero or negative price rows plus duplicate copies), dated 1 Dec 2010 08:26 to 9 Dec 2011 12:50.

## Metric definitions

- **Line total** = quantity x unit price (negative for cancellations)
- **Gross revenue** = sum of line total on non-cancelled rows
- **Net revenue** = sum of line total across all rows, so cancellations are deducted
- **Orders** = distinct non-cancelled invoice numbers
- **Cancellation rate** = cancelled invoices / all invoices, with entry errors and non-products excluded
- **Customer metrics** use only rows where CustomerID is present
- **Growth (CEO Q4)** compares Dec 2010 to May 2011 (H1) with Jun to Nov 2011 (H2). Dec 2011 is excluded. Countries with fewer than 5 customers are excluded
- **Rate reliability:** countries with fewer than 30 orders are excluded from cancellation rate rankings

## Known limitations

- Manual adjustments and Amazon fees (non-product rows) are included in net revenue (e.g. a -£38,970 "Manual" entry) but excluded from product and cancellation analysis. 
- The dataset has no cancellation reason, so product-level cancellation patterns can't be explained from the data alone.
- About 25% of rows have no CustomerID, so customer analysis covers roughly 75% of transactions.