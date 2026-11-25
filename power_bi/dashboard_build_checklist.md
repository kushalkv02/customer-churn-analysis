# Power BI Dashboard: Build Checklist

Work top to bottom. Tick each box and compare what you see with the **expected values** (they come from your SQL results on the full dataset). If a number differs, stop and fix it before moving on.

Files used: `churn_theme.json`, `measures.dax`. Full design detail is in the Power BI Build Guide.

> Power BI Desktop runs on Windows only. On a Mac, use a Windows VM or Power BI Service in the browser (limited authoring).

## Part 1: Load and model

- [ ] **Get data (CSV route, no database needed on this laptop).** Home > Get data > Text/CSV, pick `customers_export.csv`, then **Transform data** (not Load). In Power Query, rename the query from `customers_export` to `customers` (right-click the query in the left pane, or edit Name in Query Settings). The DAX measures all refer to `customers[...]`, so this name matters.
  - To make the file, run this in psql on the machine that has the database: `\copy customers TO 'customers_export.csv' WITH (FORMAT csv, HEADER true);`
  - Expected: 7,043 rows and 23 columns with snake_case headers (`customer_id`, `monthly_charges`, `tenure_group`, ...).
  - (If you do have PostgreSQL available: Home > Get data > PostgreSQL database, server `localhost`, database `churn_db`, mode Import, table `customers`.)
- [ ] **Check types** in Transform data: `senior_citizen`, `tenure`, `churn_flag` whole number; `monthly_charges`, `total_charges` fixed decimal; everything else text. Close & Apply.
- [ ] **Apply the theme.** View > Themes > Browse for themes > `churn_theme.json`.
- [ ] **Create tables.** From `measures.dax` section 1: `dim_tenure_group`, `dim_contract`, `_Measures`.
- [ ] **Relationships** (Model view): `dim_tenure_group[tenure_group]` to `customers[tenure_group]` and `dim_contract[contract]` to `customers[contract]`. Both one-to-many, single direction.
- [ ] **Sort order.** Select `dim_tenure_group[tenure_group]` > Sort by column > `sort_order`. Repeat for `dim_contract[contract]`.
- [ ] **Hide** `customers[tenure_group]`, `customers[contract]`, `customers[churn_flag]`, `customer_id`, and both `sort_order` columns.
- [ ] **Add measures** from `measures.dax` sections 2 to 4 into `_Measures`, and set each format from the comment beside it. Add the `risk_traits` calculated column to `customers` first.

## Part 2: Check the measures before building visuals

Add a temporary Card per measure (or one table) with no slicers applied.

| Measure | Expected |
|---|---|
| Total Customers | 7,043 |
| Churned Customers | 1,869 |
| Active Customers | 5,174 |
| Churn Rate | 26.5% (26.54%) |
| Retention Rate | 73.5% (73.46%) |
| Average Tenure | 32.4 (32.37) |
| Average Monthly Charges | 64.76 |
| Monthly Revenue at Risk | 139,130.85 |
| Average Revenue per Customer | 64.76 |
| High Risk Customers | 1,307 |
| High Risk Churn Rate | 60.4% |

- [ ] All match. Record the values in the Power BI column of the **Validation Log** sheet in `KPI-documentation.xlsx` (type rates as 26.54, not 0.2654).

## Part 3: Build the pages

Set the canvas to 16:9 (View > Page view > Fit to page; Format > Canvas settings). Add slicers on page 1 and use View > Sync slicers to carry them across pages.

### Page 1: Executive Overview
- [ ] Six cards: Total Customers, Churned Customers, Churn Rate, Retention Rate, Average Tenure, Monthly Revenue at Risk.
- [ ] Donut: Legend `customers[churn]`, Values Total Customers.
- [ ] Bar: Axis `dim_contract[contract]`, Values Churn Rate.
- [ ] Column: Axis `dim_tenure_group[tenure_group]`, Values Churn Rate.
- [ ] Slicers: `dim_contract[contract]`, `customers[internet_service]`, `dim_tenure_group[tenure_group]`.
- [ ] Add a subtitle under Monthly Revenue at Risk: "Historical monthly charges of churned customers. Not a forecast."

Expected: contract churn 42.7% / 11.3% / 2.8%; tenure churn 47.4%, 28.7%, 20.4%, 14.4%, 6.6%.

### Page 2: Customer Segmentation
- [ ] Bar charts of Churn Rate by contract, tenure group, `payment_method`, `internet_service`.
- [ ] Four small bar charts for `gender`, `senior_citizen`, `partner`, `dependents`.
- [ ] Tooltip fields on every visual: Total Customers, Share of Customers, Churn Rate vs Overall, Segment Size Note.

Expected: electronic check 45.3%, mailed check 19.1%, bank transfer 16.7%, credit card 15.2%; fiber optic 41.9%, DSL 19.0%, no internet 7.4%.

### Page 3: Revenue Analysis
- [ ] Cards: Average Monthly Charges, Average Revenue per Customer, Monthly Revenue at Risk.
- [ ] Column: Axis `customers[churn]`, Values Average Monthly Charges (expect 61.27 retained, 74.44 churned).
- [ ] Bars of Share of Churned Monthly Charges by contract, payment method, internet service.
- [ ] Column chart of customers by binned `monthly_charges` (Data groups > New group > bin size 10), legend `churn`.

Expected shares: month-to-month 86.9%, fiber optic 82.2%, electronic check 60.6%. Shares within each dimension sum to 100%.

### Page 4: Churn Drivers
- [ ] Matrix: rows `dim_contract[contract]`, columns `dim_tenure_group[tenure_group]`, values Churn Rate, with a red colour scale.
- [ ] Column: Axis `churn`, Values Average Tenure.
- [ ] Bar by `risk_traits` (0 to 3), Values Churn Rate. Expected 3.1%, 18.0%, 38.6%, 60.4%.
- [ ] Cards: High Risk Customers, High Risk Churn Rate, High Risk Share of Churned Customers (expect 1,307, 60.4%, 42.2%).
- [ ] Six small bar charts of Churn Rate by add-on service. Filter them to internet customers (`internet_service` not "No") so "No internet" does not blur the comparison.
- [ ] Text box: "Patterns shown are associations in historical data and do not establish causation."

Expected matrix, month-to-month row: 51.4%, 37.7%, 32.9%, 27.8%, 22.2%.

### Optional page 5: Segment Detail (drill-through)
- [ ] Table of `customer_id`, `contract`, `tenure`, `internet_service`, `payment_method`, `monthly_charges`, `churn`.
- [ ] Add `contract`, `payment_method`, `internet_service` to the Drill-through well, then hide the page.

## Part 4: Interactions and tidy-up

- [ ] Edit interactions (Format > Edit interactions): stop the donut filtering the rate visuals on page 1; stop rate visuals cross-filtering each other on pages 2 and 4.
- [ ] Every slicer changes every card as expected.
- [ ] Titles say what the chart shows (for example "Churn rate by contract type"). Same warm colour for churn on every page.
- [ ] Check the Filters pane on each page for accidental page-level filters.

## Part 5: Validate and publish to the repo

- [ ] With a Contract slicer applied, the Churn Rate values match `business_analysis.sql` Q2.
- [ ] Complete the **KPI Test Cases** sheet (T01 to T11) in `KPI-documentation.xlsx`.
- [ ] Save as `powerbi/customer_churn_dashboard.pbix`.
- [ ] Export each page as an image (File > Export, or screenshot) into `powerbi/dashboard_screenshots/`.
- [ ] Update the README status table and add screenshots to the Dashboard section.

## If a number does not match

| Symptom | Likely cause |
|---|---|
| Rates differ from SQL | A slicer or page filter is still applied. Clear all filters. |
| Percentages look like 2,654% | Rate was multiplied by 100 in DAX. Leave as a fraction and format as %. |
| Tenure groups sort alphabetically | Using the field from `customers` instead of `dim_tenure_group`, or sort by column not set. |
| Shares add to more than 100% | Share measure is using `ALL` instead of `ALLSELECTED`, or you are adding shares across dimensions. |
| `risk_traits` shows blank in visuals | The calculated column was created on the wrong table, or the model was not refreshed. |
