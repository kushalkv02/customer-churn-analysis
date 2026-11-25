-- data_validation.sql
-- Run after loading. Every query should return the expected result noted above it.
-- Keep these numbers: they are the reference for the SQL vs Power BI comparison.

-- 1. Row count and unique customers (expect equal values)
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS unique_customers
FROM customers;

-- 2. Duplicate customer IDs (expect 0 rows)
SELECT customer_id, COUNT(*) AS n
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3. NULL check across key fields (expect all zeros)
SELECT
    SUM(CASE WHEN tenure          IS NULL THEN 1 ELSE 0 END) AS null_tenure,
    SUM(CASE WHEN monthly_charges IS NULL THEN 1 ELSE 0 END) AS null_monthly,
    SUM(CASE WHEN total_charges   IS NULL THEN 1 ELSE 0 END) AS null_total,
    SUM(CASE WHEN churn           IS NULL THEN 1 ELSE 0 END) AS null_churn,
    SUM(CASE WHEN contract        IS NULL THEN 1 ELSE 0 END) AS null_contract
FROM customers;

-- 4. Category values (eyeball for typos or unexpected labels)
SELECT 'contract' AS field, contract AS value, COUNT(*) AS n FROM customers GROUP BY contract
UNION ALL
SELECT 'internet_service', internet_service, COUNT(*) FROM customers GROUP BY internet_service
UNION ALL
SELECT 'payment_method', payment_method, COUNT(*) FROM customers GROUP BY payment_method
UNION ALL
SELECT 'churn', churn, COUNT(*) FROM customers GROUP BY churn
ORDER BY field, n DESC;

-- 5. churn and churn_flag agree (expect 0 rows)
SELECT customer_id, churn, churn_flag
FROM customers
WHERE (churn = 'Yes' AND churn_flag <> 1)
   OR (churn = 'No'  AND churn_flag <> 0);

-- 6. Range checks (expect 0 rows)
SELECT customer_id, tenure, monthly_charges, total_charges
FROM customers
WHERE tenure < 0 OR monthly_charges <= 0 OR total_charges < 0;

-- 7. Plausibility: total_charges should be roughly tenure x monthly_charges.
--    Large gaps are normal (price changes), but check the extremes.
SELECT customer_id, tenure, monthly_charges, total_charges,
       ROUND(total_charges - tenure * monthly_charges, 2) AS gap
FROM customers
ORDER BY ABS(total_charges - tenure * monthly_charges) DESC
LIMIT 10;

-- 8. Reference KPIs for the Power BI reconciliation (document these values)
SELECT COUNT(*)                                             AS total_customers,
       SUM(churn_flag)                                      AS churned_customers,
       COUNT(*) - SUM(churn_flag)                           AS active_customers,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)         AS churn_rate_pct,
       ROUND(100.0 * (COUNT(*) - SUM(churn_flag)) / COUNT(*), 2) AS retention_rate_pct,
       ROUND(AVG(tenure), 2)                                AS avg_tenure_months,
       ROUND(AVG(monthly_charges), 2)                       AS avg_monthly_charges,
       ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges END), 2) AS monthly_charges_associated_with_churn,
       ROUND(SUM(monthly_charges) / COUNT(*), 2)            AS avg_revenue_per_customer
FROM customers;
