-- business_analysis.sql  (PostgreSQL)
-- One query per question in Section 10.2 of the project document.
-- Reminder: these show association in historical data, not causation.

-- Q1. What is the overall customer churn rate?
SELECT COUNT(*)                                      AS total_customers,
       SUM(churn_flag)                               AS churned_customers,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)  AS churn_rate_pct
FROM customers;

-- Q2. Which contract type has the highest churn rate?
SELECT contract,
       COUNT(*)                                      AS customers,
       SUM(churn_flag)                               AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- Q3. How does churn vary by customer tenure?
SELECT tenure_group,
       COUNT(*)                                      AS customers,
       SUM(churn_flag)                               AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY tenure_group
ORDER BY MIN(tenure);

-- Q4. Which payment methods are associated with higher churn?
SELECT payment_method,
       COUNT(*)                                      AS customers,
       SUM(churn_flag)                               AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- Q5. Which internet service category has the highest churn?
SELECT internet_service,
       COUNT(*)                                      AS customers,
       SUM(churn_flag)                               AS churned,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

-- Q6. How do monthly charges differ between churned and retained customers?
SELECT churn,
       COUNT(*)                                                         AS customers,
       ROUND(AVG(monthly_charges), 2)                                   AS avg_monthly_charges,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_charges)::numeric, 2) AS median_monthly_charges,
       ROUND(MIN(monthly_charges), 2)                                   AS min_monthly_charges,
       ROUND(MAX(monthly_charges), 2)                                   AS max_monthly_charges
FROM customers
GROUP BY churn;

-- Q7. Which customer segments contribute the most monthly charges associated with churn?
--     "Monthly charges associated with churn" = SUM(monthly_charges) for churned customers.
--     This is a historical segment measure, not a forecast of lost revenue.
WITH segments AS (
    SELECT 'contract' AS dimension, contract AS segment, monthly_charges, churn_flag FROM customers
    UNION ALL
    SELECT 'internet_service', internet_service, monthly_charges, churn_flag FROM customers
    UNION ALL
    SELECT 'payment_method', payment_method, monthly_charges, churn_flag FROM customers
    UNION ALL
    SELECT 'tenure_group', tenure_group, monthly_charges, churn_flag FROM customers
),
totals AS (
    SELECT SUM(monthly_charges) FILTER (WHERE churn_flag = 1) AS total_churn_charges
    FROM customers
)
SELECT s.dimension,
       s.segment,
       ROUND(SUM(s.monthly_charges) FILTER (WHERE s.churn_flag = 1), 2) AS churn_monthly_charges,
       ROUND(100.0 * SUM(s.monthly_charges) FILTER (WHERE s.churn_flag = 1)
             / t.total_churn_charges, 2)                                AS share_of_total_pct
FROM segments s
CROSS JOIN totals t
GROUP BY s.dimension, s.segment, t.total_churn_charges
ORDER BY churn_monthly_charges DESC;

-- Bonus: contract x tenure_group cross-tab for the Churn Drivers dashboard page
SELECT contract,
       tenure_group,
       COUNT(*)                                      AS customers,
       ROUND(100.0 * SUM(churn_flag) / COUNT(*), 2)  AS churn_rate_pct
FROM customers
GROUP BY contract, tenure_group
ORDER BY contract, MIN(tenure);
