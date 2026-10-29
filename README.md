# Olist Monthly Cohort Retention Analysis

PostgreSQL cohort queries, exported aggregate CSVs, a Python retention heatmap and a two-page Power BI report. This learning project studies repeat delivered purchases by first-order month.

## Business question and definition
How often do customers return in subsequent months? Customers are identified by customer_unique_id, not the order-specific customer_id. The cohort includes customers whose first-ever order is marked delivered. Later activity also includes delivered orders only. This differs from defining a cohort by the first delivered order regardless of prior unsuccessful orders.

Retention is distinct active customers in a cohort-age month divided by the original cohort size, multiplied by 100. Month zero is the acquisition month and is 100% by definition.

## Files
- [PostgreSQL analysis](SQL/cohort_retention.sql): joins, CTEs, ROW_NUMBER, date truncation and cohort-age calculation.
- [Aggregate exports](DATA/): cohort retention and first-order summary.
- [Python heatmap](PYTHON/cohort_analysis.py): pivot and percentage visualization.
- [Power BI report](POWER_BI/Cohort_Dashboard.pbix): cohort retention and first-order summary.

## Run
Load Olist customers and orders into PostgreSQL under the olist schema; inspect the column names expected by the SQL. Run the queries and export results using the CSV filenames in DATA. From the repository root, install requirements with `python -m pip install -r requirements.txt`, then run `python PYTHON/cohort_analysis.py`. Power BI refresh requires updating the local CSV source paths.

## Validation and limitations
The CSV is an aggregate snapshot, not a live connection. Its cohort totals and the separate first-order summary have a three-customer discrepancy that must be reconciled by rerunning both exports against the same source snapshot before operational use. The SQL file retains exploratory queries; one early first-order summary uses a timestamp-only ranking, while later queries add order_id as a deterministic tie-break.

The heatmap caps its color scale at 1%, so month zero and higher values saturate the color. Blank cells are not explicitly classified into observed zero-activity months versus future, not-yet-observed months. Recent cohorts have shorter observation windows, so lower repeat rates do not establish deteriorating customer satisfaction. The report is an exploratory portfolio exercise, not a production-ready retention forecast.

## Data source
Brazilian E-Commerce Public Dataset by Olist: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce . Only aggregate exports are included here.
