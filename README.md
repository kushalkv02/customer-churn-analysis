#Try the **Dashboard**
https://scintillating-twilight-1f83e4.netlify.app/

# Customer Churn Analysis

An end-to-end business analytics project that takes a telecom customer
dataset from raw CSV to validated churn analysis, an interactive
dashboard and retention recommendations. The workflow covers business
requirements, data cleaning, SQL analysis, KPI design, dashboarding and
evidence-based recommendations.

> **Status:** Core data preparation, SQL analysis and the interactive
> HTML dashboard are complete. The native Power BI `.pbix`
> implementation and several supporting project documents remain in
> progress. See [Project status](#project-status) for the current
> breakdown.

## Business problem

A telecom company is losing customers and wants to understand **who is
leaving, which customer segments have higher observed churn, and how
much monthly revenue is associated with customers who churned**, so it
can design and test targeted retention actions.

The analysis answers questions such as:

-   What is the overall churn rate?
-   Which contract types, tenure groups, payment methods and internet
    services show the highest churn?
-   How do monthly charges differ between churned and retained
    customers?
-   Which customer segments account for the most monthly charges
    associated with churn?
-   How does the combination of contract type, internet service and
    payment method relate to churn?

> **Interpretation note:** Findings are associations in historical data.
> They do not establish causation. Retention recommendations are
> hypotheses to test, not proven interventions.

## Architecture

  -----------------------------------------------------------------------
  Layer                               Activities / technology
  ----------------------------------- -----------------------------------
  1\. Data source                     IBM Telco customer churn dataset
                                      (CSV)

  2\. Ingestion                       Import raw records, validate
                                      structure and inspect completeness

  3\. Preparation                     Python (Pandas, NumPy): data types,
                                      missing values, duplicates and
                                      categories

  4\. Storage                         PostgreSQL or MySQL: cleaned
                                      customer table

  5\. Analytics                       SQL and Python: churn metrics,
                                      segmentation and overlap analysis

  6\. Visualization                   Interactive HTML dashboard; Power
                                      BI theme, DAX measures and build
                                      guide prepared

  7\. Decision layer                  Findings, limitations and retention
                                      recommendations
  -----------------------------------------------------------------------

For a dataset of this size, the cleaned CSV can be imported directly
into Power BI. The database layer is included to demonstrate a reusable
analytics workflow.

## Repository structure

``` text
customer-churn-analysis/
|-- README.md
|-- requirements.txt
|-- documentation/
|   |-- KPI-documentation.xlsx        KPI definitions, SQL/DAX, validation log, test cases
|   |-- power-bi-build-guide          Data model, DAX measures, page layouts
|   |-- (planned) project-charter, BRD, stakeholder-analysis,
|   |             data-dictionary, business-insights, recommendations
|-- dataset/
|   |-- README.md                     Source, field dictionary, known data quirks
|   |-- (local) raw and cleaned CSV files
|-- python/
|   |-- data_cleaning.py              Cleaning + validation, writes data_quality_log.json
|   |-- exploratory_analysis.ipynb    EDA notebook with SQL reconciliation check
|-- sql/
|   |-- schema.sql                    Table definition and load command
|   |-- data_validation.sql           Integrity checks and reference KPI values
|   |-- business_analysis.sql         One query per business question
|   |-- overlap_analysis.sql           Combined risk-trait analysis
|-- powerbi/
|   |-- churn_theme.json              Importable Power BI theme
|   |-- measures.dax                  Helper tables, KPIs and supporting measures
|   |-- dashboard_build_checklist.md  Step-by-step Power BI build with expected values
|   |-- (planned) customer_churn_dashboard.pbix
|   |-- (planned) dashboard_screenshots/
|-- dashboard/
|   |-- ibm_telco_churn_interactive_dashboard.html
|-- architecture/
|   |-- (planned) system_architecture.png, process_flow.png
|-- presentation/
    |-- (planned) final_project_presentation.pptx
```

The interactive HTML dashboard is a browser-based deliverable, not a
Power BI `.pbix` file. The dashboard contains embedded customer data and
uses Chart.js from a CDN, so an internet connection is required to load
its charts.

## How to reproduce

**Prerequisites:** Python 3.9+, PostgreSQL (or MySQL), and a browser.
Power BI Desktop is required only for the planned native Power BI
implementation.

1.  **Get the data.** Download the IBM Telco customer churn CSV and
    place it in `dataset/`. See [dataset/README.md](dataset/README.md)
    for the source and field dictionary.

2.  **Install dependencies.**

    ``` bash
    pip install -r requirements.txt
    ```

3.  **Clean and validate.**

    ``` bash
    cd python
    python data_cleaning.py \
      --input ../dataset/WA_Fn-UseC_-Telco-Customer-Churn.csv \
      --output ../dataset/telco_churn_clean.csv
    ```

    This writes the cleaned CSV and `data_quality_log.json` (rows,
    duplicates, missing values, validation checks and churn rate).
    Adjust the input filename if yours differs.

4.  **Load into the database.** Run `sql/schema.sql`, then load the
    cleaned CSV with the `\copy` command at the bottom of that file
    (PostgreSQL) or `LOAD DATA LOCAL INFILE` (MySQL).

5.  **Validate.** Run `sql/data_validation.sql`. Compare the checks and
    reference KPI values with the results documented in the KPI
    workbook.

6.  **Analyse.** Run `sql/business_analysis.sql` for the business
    questions and contract-by-tenure cross-tab. Run
    `sql/overlap_analysis.sql` for the combined risk-trait analysis.

7.  **Explore the dashboard.** Open
    `dashboard/ibm_telco_churn_interactive_dashboard.html` in a modern
    browser. The customer data is embedded in the file; an internet
    connection is needed for the Chart.js library loaded from its CDN.

8.  **Build the native Power BI version (planned).** Follow the Power BI
    build guide, import the cleaned CSV or database table, add
    `powerbi/measures.dax`, and reconcile each visual against the
    reference values.

> `business_analysis.sql` is written for PostgreSQL (`FILTER`,
> `PERCENTILE_CONT`). MySQL needs small edits: replace `FILTER` with
> `CASE` expressions and calculate the median using an alternative
> method.

## KPIs

Nine core KPIs are defined consistently across SQL and DAX (full
definitions in `documentation/KPI-documentation.xlsx`):

1.  Total Customers
2.  Churned Customers
3.  Active Customers
4.  Churn Rate
5.  Retention Rate
6.  Average Tenure
7.  Average Monthly Charges
8.  Monthly Revenue at Risk
9.  Average Revenue per Customer

**Metric caveat:** *Monthly Revenue at Risk* is the sum of monthly
charges for customers who churned. It is a historical segment measure,
not a forecast of future lost revenue.

### Combined high-risk segment

The overlap analysis defines `risk_traits` as a customer-level score
from 0 to 3. One point is added for each condition:

-   Contract is `Month-to-month`.
-   Internet service is `Fiber optic`.
-   Payment method is `Electronic check`.

A customer is classified in the combined high-risk segment when
`risk_traits = 3`, meaning all three conditions apply.

  Measure                                                Full-dataset result
  ---------------------------------------------------- ---------------------
  High-risk customers                                                  1,307
  High-risk customers as a share of all customers                      18.6%
  High-risk churn rate                                                 60.4%
  High-risk share of all churned customers                             42.2%
  High-risk share of churned monthly charges                           49.1%
  Churn rate for everyone outside the combined group                   18.8%

**Churn rate by risk-trait count**

    Number of traits   Churn rate
  ------------------ ------------
                   0         3.1%
                   1        18.0%
                   2        38.6%
                   3        60.4%

These are descriptive segment measures, not a predictive model or causal
estimate. In the interactive dashboard, the high-risk KPIs and
risk-trait visual respond to the dashboard's available filters.

## Dashboard

The completed interactive HTML dashboard has five pages:

1.  **Executive Overview** --- headline KPIs, overall churn, contract
    and tenure comparisons.
2.  **Customer Segmentation** --- churn patterns across contract,
    tenure, payment method, internet service and demographic segments.
3.  **Revenue Analysis** --- monthly charges by churn status, charge
    distribution and the share of churned monthly charges by segment.
4.  **Churn Drivers** --- contract-by-tenure churn matrix, risk-trait
    analysis, high-risk segment KPIs and internet add-on comparisons.
5.  **Segment Detail** --- searchable and paginated customer-level
    table.

Global filters allow users to explore the dashboard by contract,
internet service and tenure. Segment visuals include contextual details
such as customer counts, segment shares and churn-rate comparisons.

The HTML dashboard is available at:

`dashboard/ibm_telco_churn_interactive_dashboard.html`

The native Power BI `.pbix` file and dashboard screenshots are not yet
complete. The Power BI theme, measures and build checklist are prepared
for that next stage.

## Key findings

Overall churn is **26.5%** (1,869 of 7,043 customers). The monthly
charges associated with those churned customers total **139,130.85**.
The dataset does not specify a currency, so the amount is reported
without a currency symbol.

All findings below describe associations in the historical dataset; they
do not show that any trait causes churn.

### Single-factor patterns

-   **Contract:** month-to-month customers churn at 42.7%, versus 11.3%
    for one-year and 2.8% for two-year contracts.
-   **Tenure:** churn falls from 47.4% in the first 12 months to 6.6%
    after 60 months.
-   **Payment method:** electronic check customers churn at 45.3%; the
    other three methods range from 15.2% to 19.1%.
-   **Internet service:** fiber optic customers churn at 41.9%, versus
    19.0% for DSL and 7.4% for customers with no internet service.
-   **Charges:** churned customers pay more per month on average (74.44
    versus 61.27; medians 79.65 versus 64.43).

### Combined patterns

-   1,307 customers (18.6%) are month-to-month, use fiber optic internet
    and pay by electronic check. This group churns at **60.4%** and
    accounts for **42.2% of all churned customers** and **49.1% of
    churned monthly charges**. Everyone outside this combined group
    churns at 18.8%.
-   The traits stack descriptively: churn is 3.1% with none of the three
    traits, 18.0% with one, 38.6% with two and 60.4% with all three.
-   The traits do not identify the same customers: 28.0% of customers
    have none of them, while 18.6% have all three.
-   Contract type still matters inside the same internet-service and
    payment-method group. For example, DSL with bank transfer churns at
    19.8% on month-to-month contracts versus 3.8% on longer contracts;
    fiber optic with electronic check churns at 60.4% versus 20.8%.
-   Fiber optic and electronic check customers on longer contracts still
    churn more than DSL customers on longer contracts (for instance,
    20.8% for fiber optic with electronic check, against 3.8% to 8.6%
    for DSL), so contract type does not explain every observed
    difference.

### Limitations of these findings

-   Some groups are small (for example, one-year fiber optic customers
    paying by mailed check number 36), so their rates are unstable.
-   The dataset gives no dates, so it is not possible to determine when
    customers churned or whether these patterns still hold today.
-   Overlapping segments mean the share-of-churn figures by individual
    dimension can add up to more than 100% and should not be summed.
-   Segment comparisons are descriptive. They do not control for all
    possible confounding factors and do not establish why customers
    churn.

### Hypotheses to test with stakeholders

-   Offer incentives to move new month-to-month customers to longer
    contracts, and compare retention against a control group.
-   Investigate billing friction and the payment experience for
    electronic-check customers.
-   Investigate service quality, pricing and value perception for fiber
    optic customers.
-   Focus an initial retention pilot on the 1,307-customer combined
    group, where the observed churn rate is highest. Define eligibility,
    treatment, outcome window and a comparison group before evaluating
    impact.

## Project status

  -----------------------------------------------------------------------
  Deliverable                         Status
  ----------------------------------- -----------------------------------
  Data cleaning script                Done: run on the full dataset
  (`data_cleaning.py`)                (7,043 customers; none dropped)

  SQL schema, validation and business Done: data loaded, validation
  analysis                            checks passed, business and overlap
                                      queries run

  KPI documentation                   Done: SQL values recorded; native
                                      Power BI reconciliation remains
                                      pending

  Power BI build guide                Done

  Exploratory analysis notebook       Written; run it on the cleaned data
                                      and save the outputs

  Interactive HTML dashboard          Done: five pages, global filters,
                                      segment analysis and customer
                                      detail

  Native Power BI dashboard (`.pbix`) In progress: theme, DAX measures
                                      and build checklist ready; report
                                      file still to be built

  Dashboard screenshots               Pending

  Insights and recommendations        Drafted; export and finalize in
  reports                             `documentation/`

  Business Requirements Document      Drafted; export and finalize in
                                      `documentation/`

  Project charter and stakeholder     Planned
  analysis                            

  Data dictionary                     Planned

  Architecture diagrams               Planned

  Final presentation                  Planned
  -----------------------------------------------------------------------

Update this table as each item is completed. Keep the HTML dashboard and
native Power BI report listed separately because they are different
deliverables.

## Assumptions and limitations

-   Historical customer data is available and sufficiently complete, and
    churn status is accurately recorded.
-   The dataset does not state a reporting period or currency; both
    remain open questions in the KPI workbook.
-   Historical patterns may not represent current customer behavior.
-   Associations shown here should be validated with stakeholders before
    action.
-   The combined high-risk group is a descriptive rule-based segment,
    not a trained churn prediction model.
-   The HTML dashboard loads Chart.js from a CDN and therefore requires
    internet access for its charts.

## Tools

Python (Pandas, NumPy, Matplotlib, Seaborn), PostgreSQL / MySQL, SQL,
Power BI and DAX, Excel, HTML, JavaScript, Chart.js, Draw.io and GitHub.
