# Findings

Net revenue figures use the definitions in `cleaning_decisions.md`.
Data period: 1 Dec 2010 to 9 Dec 2011 (Dec 2011 is partial).

## CEO Q1: What drives net revenue?

**By time**
- Total net revenue is about £9.75M.
- Jan to Aug 2011 averages roughly £630K a month, then it takes off: Sep £1.02M, Oct £1.07M, Nov £1.46M.
- November is more than double a typical month, which suggests a pre-Christmas buying cycle (many of the top products are Christmas or decor items).
- Dec 2011 (£433K) is partial and not comparable.

**By country**
- The UK accounts for 84% of net revenue (£8.19M).
- Next: Netherlands 2.9%, EIRE 2.7%, Germany 2.3%, France 2.0%, Australia 1.4%.
- Average order value differs sharply: UK about £454, Netherlands about £3,030 (94 orders), Australia about £2,400 (57 orders). A few large buyers drive these two markets.

**By product**
- Top by net revenue: Regency Cakestand 3 Tier (£164K), Party Bunting (£98K), White Hanging Heart T-Light Holder (£98K), Jumbo Bag Red Retrospot (£92K), Rabbit Night Light (£67K).

## CEO Q2: Cancellations by country

- Raw (before entry-error adjustment): the UK shows £812K in cancelled revenue, but about £320K of the company-wide total comes from five rows: two entry errors and three non-customer entries (a Manual adjustment and two Amazon fees). The raw figures overstate cancellations.
- Before the revised query, Germany (24%), EIRE (20%) and the UK (15.8%) were above France (15%).
- TODO: paste the revised Q2 results (real products only, entry errors excluded, minimum 30 orders) and replace the raw figures above.

## CEO Q3: Products with high cancellation rates

- Best sellers are low: Jumbo Bag Red Retrospot 2.3%, Regency Cakestand 6.2%, White Hanging Heart 6.9%.
- Highest: Pantry Chopping Board 82% (946 of 1,154 units), Flowers Chandelier T-Light Holder 60%, Tea Time Party Bunting 60%, Feltcraft Doll Molly 32%, Fairy Cake Flannel 31%.
- The data can't explain why, so these are products to investigate.
- TODO: add `revenue_lost` per product (the column was cut off in the screenshot).

## CEO Q4: Expansion candidates

Net revenue and half-year growth (H1 = Dec 2010 to May 2011, H2 = Jun to Nov 2011):

| Country | Net revenue | H1 | H2 | Growth |
|---|---|---|---|---|
| United Kingdom | £7.80M | £3.11M | £4.69M | +51% |
| Netherlands | £273K | £113K | £160K | +42% |
| Germany | £214K | £92K | £122K | +33% |
| France | £190K | £72K | £119K | +65% |
| Australia | £137K | £56K | £81K | +46% |
| Switzerland | £56K | £15K | £41K | +165% |
| Spain | £54K | £21K | £33K | +54% |
| Belgium | £40K | £13K | £26K | +101% |
| Japan | £35K | £20K | £16K | -18% |
| Norway | £32K | £5K | £28K | +485% |

- Growth is inflated for every country because H2 contains the Sep to Nov seasonal peak. The UK's +51% is the baseline, so only growth well above it is meaningful.
- France (+65%), Belgium (+101%) and Switzerland (+165%) outgrew the UK. Germany and the Netherlands grew slower than the UK. Japan fell.
- Norway's +485% comes from a very small base (£5K), so it is not a reliable signal.
- TODO: add customer counts (customers_h1, customers_h2, customers_total) and cancel rates from the Q4 output, then name the shortlist: strong revenue, growing customers and a cancellation rate at or below the overall average.

## Data quality findings

- Two line items of 74K and 81K units were sold and fully cancelled, which inflated cancellation metrics until flagged.
- About 25% of transactions have no CustomerID.

## Recommendations (draft)

- Plan inventory and campaigns around the Sep to Nov peak, which brings about 40% of the Dec 2010 to Nov 2011 revenue from three months.
- Reduce dependence on the UK by focusing on the countries that outgrew it (final shortlist after Q4 customer and cancellation data).
- Investigate the products with very high cancellation rates before promoting them.