-- schema.sql  (PostgreSQL)
-- Stores the cleaned output of python/data_cleaning.py
-- MySQL note: replace BOOLEAN-style checks with TINYINT, and \copy with LOAD DATA LOCAL INFILE.

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id        VARCHAR(20)   PRIMARY KEY,
    gender             VARCHAR(10)   NOT NULL,
    senior_citizen     SMALLINT      NOT NULL CHECK (senior_citizen IN (0, 1)),
    partner            VARCHAR(3)    NOT NULL CHECK (partner IN ('Yes', 'No')),
    dependents         VARCHAR(3)    NOT NULL CHECK (dependents IN ('Yes', 'No')),
    tenure             INTEGER       NOT NULL CHECK (tenure >= 0),
    phone_service      VARCHAR(3)    NOT NULL,
    multiple_lines     VARCHAR(3)    NOT NULL,
    internet_service   VARCHAR(20)   NOT NULL,   -- DSL / Fiber optic / No
    online_security    VARCHAR(3)    NOT NULL,
    online_backup      VARCHAR(3)    NOT NULL,
    device_protection  VARCHAR(3)    NOT NULL,
    tech_support       VARCHAR(3)    NOT NULL,
    streaming_tv       VARCHAR(3)    NOT NULL,
    streaming_movies   VARCHAR(3)    NOT NULL,
    contract           VARCHAR(20)   NOT NULL,   -- Month-to-month / One year / Two year
    paperless_billing  VARCHAR(3)    NOT NULL,
    payment_method     VARCHAR(40)   NOT NULL,
    monthly_charges    NUMERIC(8, 2) NOT NULL CHECK (monthly_charges > 0),
    total_charges      NUMERIC(10, 2) NOT NULL CHECK (total_charges >= 0),
    churn              VARCHAR(3)    NOT NULL CHECK (churn IN ('Yes', 'No')),
    churn_flag         SMALLINT      NOT NULL CHECK (churn_flag IN (0, 1)),
    tenure_group       VARCHAR(20)   NOT NULL
);

CREATE INDEX idx_customers_churn    ON customers (churn);
CREATE INDEX idx_customers_contract ON customers (contract);

-- Load the cleaned CSV (run from psql; column order must match the CSV header order).
-- The CSV produced by data_cleaning.py has columns in this order:
--   customerID, gender, SeniorCitizen, Partner, Dependents, tenure, PhoneService,
--   MultipleLines, InternetService, OnlineSecurity, OnlineBackup, DeviceProtection,
--   TechSupport, StreamingTV, StreamingMovies, Contract, PaperlessBilling,
--   PaymentMethod, MonthlyCharges, TotalCharges, Churn, churn_flag, tenure_group
--
-- \copy customers FROM 'dataset/telco_churn_clean.csv' WITH (FORMAT csv, HEADER true);
