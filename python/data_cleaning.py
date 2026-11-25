"""
Data cleaning and validation for the IBM Telco Customer Churn dataset.

Usage:
    python data_cleaning.py --input ../dataset/WA_Fn-UseC_-Telco-Customer-Churn.csv \
                            --output ../dataset/telco_churn_clean.csv

Steps (maps to Section 8.1, layers 2-3 of the project document):
    1. Ingest raw CSV and inspect structure
    2. Validate completeness, duplicates, and ID integrity
    3. Fix data types (TotalCharges arrives as text with blank values)
    4. Standardise inconsistent categories
    5. Add derived fields used by SQL / Power BI (tenure_group, churn_flag)
    6. Export a cleaned CSV and a short data-quality log
"""

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd

EXPECTED_COLUMNS = [
    "customerID", "gender", "SeniorCitizen", "Partner", "Dependents", "tenure",
    "PhoneService", "MultipleLines", "InternetService", "OnlineSecurity",
    "OnlineBackup", "DeviceProtection", "TechSupport", "StreamingTV",
    "StreamingMovies", "Contract", "PaperlessBilling", "PaymentMethod",
    "MonthlyCharges", "TotalCharges", "Churn",
]

# Columns where "No internet service" / "No phone service" mean the same as "No"
# for the purpose of simple yes/no analysis. The original value is kept in the
# *_raw columns only if you set KEEP_RAW_SERVICE_COLUMNS = True.
SERVICE_COLUMNS = [
    "MultipleLines", "OnlineSecurity", "OnlineBackup", "DeviceProtection",
    "TechSupport", "StreamingTV", "StreamingMovies",
]
KEEP_RAW_SERVICE_COLUMNS = False

TENURE_BINS = [-1, 12, 24, 48, 60, np.inf]
TENURE_LABELS = ["0-12 months", "13-24 months", "25-48 months",
                 "49-60 months", "61+ months"]


def load_raw(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path, dtype=str)  # read everything as text first, convert deliberately
    df.columns = df.columns.str.strip()
    return df


def validate_structure(df: pd.DataFrame, log: dict) -> None:
    missing_cols = [c for c in EXPECTED_COLUMNS if c not in df.columns]
    extra_cols = [c for c in df.columns if c not in EXPECTED_COLUMNS]
    log["rows_raw"] = int(len(df))
    log["columns_raw"] = int(df.shape[1])
    log["missing_expected_columns"] = missing_cols
    log["unexpected_columns"] = extra_cols
    if missing_cols:
        raise ValueError(f"Missing expected columns: {missing_cols}")


def clean(df: pd.DataFrame, log: dict) -> pd.DataFrame:
    df = df.copy()

    # Trim whitespace in every text column
    for col in df.columns:
        df[col] = df[col].str.strip()

    # Treat empty strings as missing
    df = df.replace({"": np.nan})
    log["missing_values_by_column_raw"] = {
        c: int(v) for c, v in df.isna().sum().items() if v > 0
    }

    # Duplicates
    log["duplicate_rows"] = int(df.duplicated().sum())
    log["duplicate_customer_ids"] = int(df["customerID"].duplicated().sum())
    df = df.drop_duplicates()
    df = df.drop_duplicates(subset="customerID", keep="first")

    # Data types
    numeric_cols = ["tenure", "MonthlyCharges", "TotalCharges", "SeniorCitizen"]
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    # TotalCharges is blank for customers with tenure == 0 (brand-new accounts).
    # Nothing has been billed yet, so 0 is the correct value, not an imputed guess.
    zero_tenure_blank = df["TotalCharges"].isna() & (df["tenure"] == 0)
    log["totalcharges_blank_with_zero_tenure"] = int(zero_tenure_blank.sum())
    df.loc[zero_tenure_blank, "TotalCharges"] = 0.0

    still_missing = df["TotalCharges"].isna()
    log["totalcharges_still_missing_after_fix"] = int(still_missing.sum())
    if still_missing.any():
        # Do not silently invent values: drop and record the exclusion.
        log["rows_dropped_missing_totalcharges"] = int(still_missing.sum())
        df = df[~still_missing]

    df["tenure"] = df["tenure"].astype(int)
    df["SeniorCitizen"] = df["SeniorCitizen"].astype(int)

    # Standardise categories
    if KEEP_RAW_SERVICE_COLUMNS:
        for col in SERVICE_COLUMNS:
            df[f"{col}_raw"] = df[col]
    for col in SERVICE_COLUMNS:
        df[col] = df[col].replace({"No internet service": "No",
                                   "No phone service": "No"})

    # Shorten payment method labels so "(automatic)" does not clutter charts
    df["PaymentMethod"] = df["PaymentMethod"].str.replace(
        r"\s*\(automatic\)", "", regex=True
    )

    # Derived fields
    df["churn_flag"] = (df["Churn"] == "Yes").astype(int)
    df["tenure_group"] = pd.cut(df["tenure"], bins=TENURE_BINS,
                                labels=TENURE_LABELS)
    df["tenure_group"] = df["tenure_group"].astype(str)

    return df


def validate_clean(df: pd.DataFrame, log: dict) -> None:
    checks = {
        "customer_id_unique": bool(df["customerID"].is_unique),
        "no_nulls_remaining": bool(df.isna().sum().sum() == 0),
        "churn_values_valid": bool(df["Churn"].isin(["Yes", "No"]).all()),
        "tenure_non_negative": bool((df["tenure"] >= 0).all()),
        "monthly_charges_positive": bool((df["MonthlyCharges"] > 0).all()),
        "total_charges_non_negative": bool((df["TotalCharges"] >= 0).all()),
    }
    log["validation_checks"] = checks
    log["rows_clean"] = int(len(df))
    log["churned_customers"] = int(df["churn_flag"].sum())
    log["churn_rate_pct"] = round(float(df["churn_flag"].mean() * 100), 2)
    failed = [k for k, ok in checks.items() if not ok]
    if failed:
        print(f"WARNING: validation checks failed: {failed}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    log: dict = {}
    raw = load_raw(args.input)
    validate_structure(raw, log)
    cleaned = clean(raw, log)
    validate_clean(cleaned, log)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    cleaned.to_csv(args.output, index=False)
    log_path = args.output.with_name("data_quality_log.json")
    log_path.write_text(json.dumps(log, indent=2))

    print(json.dumps(log, indent=2))
    print(f"\nCleaned data written to {args.output}")
    print(f"Data-quality log written to {log_path}")


if __name__ == "__main__":
    main()
