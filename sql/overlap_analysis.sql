-- overlap_analysis.sql  (PostgreSQL)
-- Do month-to-month, fiber optic and electronic check customers overlap,
-- and how much churn sits in the combined group?
-- Run one query at a time. These show association in historical data, not causation.

-- O1. Full three-way breakdown: contract x internet_service x payment_method
--     Small cells (customers < 30) are flagged: treat their rates with caution.
SELECT contract,
       internet_service,
       payment_method,
       COUNT(*)                                                    AS customers,
       SUM(churn_flag)                                             AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)                AS churn_rate_pct,
       ROUND(100.0 * SUM(churn_flag) / SUM(SUM(churn_flag)) OVER (), 2) AS share_of_all_churned_pct,
       CASE WHEN COUNT(*) < 30 THEN 'small group' ELSE '' END      AS note
FROM customers
GROUP BY contract, internet_service, payment_method
ORDER BY churned DESC;

-- O2. How the three risk traits overlap (8 combinations of Yes/No flags)
--     Shows whether these are largely the same customers.
WITH flags AS (
    SELECT customer_id,
           churn_flag,
           monthly_charges,
           (contract = 'Month-to-month')            AS is_month_to_month,
           (internet_service = 'Fiber optic')       AS is_fiber,
           (payment_method = 'Electronic check')    AS is_echeck
    FROM customers
)
SELECT is_month_to_month,
       is_fiber,
       is_echeck,
       COUNT(*)                                                    AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)          AS share_of_customers_pct,
       SUM(churn_flag)                                             AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)                AS churn_rate_pct
FROM flags
GROUP BY is_month_to_month, is_fiber, is_echeck
ORDER BY customers DESC;

-- O3. Churn by number of risk traits (0 to 3)
--     Do the traits stack, i.e. does churn rise with each one added?
WITH flags AS (
    SELECT churn_flag,
           monthly_charges,
           (contract = 'Month-to-month')::int
         + (internet_service = 'Fiber optic')::int
         + (payment_method = 'Electronic check')::int AS risk_traits
    FROM customers
)
SELECT risk_traits,
       COUNT(*)                                                    AS customers,
       SUM(churn_flag)                                             AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)                AS churn_rate_pct,
       ROUND(100.0 * SUM(churn_flag) / SUM(SUM(churn_flag)) OVER (), 2) AS share_of_all_churned_pct,
       ROUND(SUM(monthly_charges) FILTER (WHERE churn_flag = 1), 2) AS churn_monthly_charges,
       ROUND(100.0 * SUM(monthly_charges) FILTER (WHERE churn_flag = 1)
             / SUM(SUM(monthly_charges) FILTER (WHERE churn_flag = 1)) OVER (), 2) AS share_of_churn_charges_pct
FROM flags
GROUP BY risk_traits
ORDER BY risk_traits;

-- O4. The combined group vs everyone else
--     "Combined group" = month-to-month AND fiber optic AND electronic check.
WITH profile AS (
    SELECT churn_flag,
           monthly_charges,
           CASE WHEN contract = 'Month-to-month'
                 AND internet_service = 'Fiber optic'
                 AND payment_method = 'Electronic check'
                THEN 'All three traits' ELSE 'All other customers' END AS grp
    FROM customers
)
SELECT grp,
       COUNT(*)                                                    AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)          AS share_of_customers_pct,
       SUM(churn_flag)                                             AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)                AS churn_rate_pct,
       ROUND(100.0 * SUM(churn_flag) / SUM(SUM(churn_flag)) OVER (), 2) AS share_of_all_churned_pct,
       ROUND(SUM(monthly_charges) FILTER (WHERE churn_flag = 1), 2) AS churn_monthly_charges,
       ROUND(100.0 * SUM(monthly_charges) FILTER (WHERE churn_flag = 1)
             / SUM(SUM(monthly_charges) FILTER (WHERE churn_flag = 1)) OVER (), 2) AS share_of_churn_charges_pct
FROM profile
GROUP BY grp
ORDER BY grp;

-- O5. Does contract still matter once internet service and payment method are held fixed?
--     Compares month-to-month with longer contracts inside the same internet/payment group.
SELECT internet_service,
       payment_method,
       CASE WHEN contract = 'Month-to-month' THEN 'Month-to-month' ELSE 'One/Two year' END AS contract_group,
       COUNT(*)                                     AS customers,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY internet_service, payment_method,
         CASE WHEN contract = 'Month-to-month' THEN 'Month-to-month' ELSE 'One/Two year' END
ORDER BY internet_service, payment_method, contract_group;
