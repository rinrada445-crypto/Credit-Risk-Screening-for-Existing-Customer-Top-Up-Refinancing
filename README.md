the 3,657 employed applicants rejected mainly for DTI > 50%, offer a loan that absorbs external high-cost debt, lowers total monthly payments and moves them into the eligible range.
- **Loan term adjustments:** for applicants who fail only on the < 8,000 THB residual income rule, offer automated tenor extension # Credit Risk Screening for Existing Customer Top-Up / Refinancing

A risk-based applicant screening engine that answers one question:

> **If all existing customers in our database applied for additional credit at the same time, how could the institution screen and filter them effectively?**

The project combines **SQL** (data cleaning, rule-based screening, KPI aggregation) with **Python machine learning** (Logistic Regression and XGBoost) to separate high-potential applicants from high-risk ones, quantify the financial impact, and surface the product and policy opportunities hidden in the rejected segments.

---

## Table of Contents

- [Objectives](#objectives)
- [Key Findings](#key-findings)
- [Dataset](#dataset)
- [Screening Rules](#screening-rules)
- [Project Structure](#project-structure)
- [Methodology](#methodology)
  - [1. SQL Pipeline](#1-sql-pipeline)
  - [2. Financial Impact Analysis](#2-financial-impact-analysis)
  - [3. Segment & Reject Reason Matrix](#3-segment--reject-reason-matrix)
  - [4. Machine Learning Models](#4-machine-learning-models)
- [Results](#results)
- [Recommendations](#recommendations)
- [Notes & Limitations](#notes--limitations)
- [Getting Started](#getting-started)
- [Tech Stack](#tech-stack)
- [Data Source](#data-source)

---

## Objectives

1. **Risk-based applicant screening** – Separate eligible customers (*Passed*) from high-risk applicants (*Rejected*) using predefined behavioral red-flag rules, and record the primary reason for each rejection.
2. **Portfolio exposure** – Quantify the total loan volume that would be disbursed to passed applicants and the total value of rejected applications, to support liquidity planning and risk assessment.
3. **Risk triggers by employment segment** – Show how rejection reasons are distributed across employment categories, to inform credit policy and targeted product design.
4. **SQL analytics** – Clean, query and aggregate the applicant dataset to derive KPIs such as approval/rejection ratios and segment-level risk metrics.
5. **Automated screening in Python** – Build and compare classification models that reproduce the screening decision automatically.

---

## Key Findings

| Metric | Value |
|---|---|
| Applicants analysed | **135,000** |
| Passed / Rejected | **62,930** / **72,070** (53.4% rejected) |
| Loan volume requested by rejected applicants | **3.63 billion THB** |
| Estimated annual interest revenue from passed applicants | **436.60 million THB** |
| Avg. loan request – Passed vs. Rejected | 57,830.56 THB vs. 50,369.40 THB |
| Most common red flag | **Low residual income** – 68,893 applicants (51.0% of the pool) |
| Highest-risk behavioral pattern | `credit_seeking` – reject rate 58.2% – 60.0% across all employment types |
| Best model | **XGBoost** – 1.00 accuracy on the test set (reproduces the screening rules exactly) |
| Interpretable model | **Logistic Regression** – 0.93 accuracy |

---

## Dataset

The dataset consolidates customer demographic profiles and historical financial behavior for **135,000 existing customers**, enriched with derived metrics that determine the final screening outcome.

| Group | Column | Description |
|---|---|---|
| **Demographic & employment** | `customer_id` | Unique customer identifier |
| | `age` | Applicant age (years) |
| | `gender` | Applicant gender |
| | `employment_status` | `employed`, `self-employed`, `unemployed` |
| **Financial & debt** | `monthly_income` | Gross monthly income (THB) |
| | `loan_amount` | Requested top-up / refinancing amount (THB) |
| | `emi` | Current Equated Monthly Installment obligations (THB) |
| | `dti` | Debt-to-Income ratio |
| | `credit_score_origination` | Credit score at origination |
| | `interest_rate` | Interest rate (%), used for revenue estimation |
| **Behavioral indicators** | `revolving_utilization_origination` | Revolving credit utilization at origination |
| | `credit_inquiries_12m` | Credit bureau inquiries in the past 12 months |
| | `deterioration_pattern` | `stable`, `gradual_decline`, `sudden_shock`, `credit_seeking` |
| **Derived outputs** | `residual_income` | `monthly_income - emi` |
| | `screening_status` | `Passed` / `Rejected` |
| | `reject_reason` | Primary rejection trigger, by priority order |

**Sample of the screened output**

| customer_id | age | employment_status | monthly_income | loan_amount | emi | residual_income | dti | credit_inquiries_12m | deterioration_pattern | screening_status | reject_reason |
|---|---|---|---|---|---|---|---|---|---|---|---|
| CUST150929 | 29 | self-employed | 5,689.42 | 50,000 | 1,044.97 | 4,644.45 | 0.34 | 3 | stable | Rejected | Low Residual Income (<8,000 THB) |
| CUST166426 | 42 | employed | 9,570.75 | 50,000 | 791.57 | 8,779.18 | 0.43 | 4 | stable | Passed | Eligible |
| CUST143553 | 37 | self-employed | 18,835.33 | 67,683 | 1,572.41 | 17,262.92 | 0.37 | 3 | stable | Passed | Eligible |
| CUST219790 | 32 | employed | 6,378.08 | 50,000 | 1,147.92 | 5,230.16 | 0.16 | 2 | sudden_shock | Rejected | Low Residual Income (<8,000 THB) |

---

## Screening Rules

An applicant is **Rejected** if *any* of the four red-flag conditions is triggered. The `reject_reason` is assigned using the priority order below. Applicants who trigger none are **Eligible** for top-up consideration.

| Priority | Red flag | Rule | Meaning |
|---|---|---|---|
| 1 | High DTI burden | `dti > 0.50` | Over half of monthly income is already committed to debt |
| 2 | High credit utilization | `revolving_utilization_origination > 0.85` | Heavy reliance on revolving credit; potential liquidity stress |
| 3 | Credit-seeking behavior | `credit_inquiries_12m >= 4` **and** `deterioration_pattern = 'credit_seeking'` | Aggressive credit acquisition |
| 4 | Low residual income | `monthly_income - emi < 8,000 THB` | Insufficient cash flow to service additional credit |

---

## Project Structure

> Adjust file names to match your repository.

```
.
├── README.md
├── sql/
│   ├── 01_backup_data.sql
│   ├── 02_data_cleansing.sql
│   ├── 03_screening_query.sql
│   ├── 04_segment_profile.sql
│   ├── 05_financial_impact.sql
│   └── 06_segment_reject_reason_matrix.sql
├── notebooks/
│   └── classification_model.ipynb
├── data/
│   └── Result.csv                # output of the screening query
├── images/
│   ├── logreg_classification_report.png
│   ├── xgboost_classification_report.png
│   ├── confusion_matrix.png
│   └── feature_importance.png
└── requirements.txt
```

---

## Methodology

### 1. SQL Pipeline

**a) Back up the raw data**

```sql
USE info;

CREATE TABLE raw_data_backup LIKE raw_data_1;
INSERT INTO raw_data_backup SELECT * FROM raw_data_1;
```

**b) Data cleansing** – trim whitespace, normalise casing, and cast to proper types (only for records with a valid `customer_id`).

```sql
UPDATE raw_data_backup
SET
    customer_id = TRIM(customer_id),
    age = CAST(age AS UNSIGNED),
    gender = LOWER(TRIM(gender)),
    employment_status = LOWER(TRIM(employment_status)),
    revolving_utilization_origination = CAST(revolving_utilization_origination AS DECIMAL(5,2)),
    deterioration_pattern = LOWER(TRIM(deterioration_pattern))
WHERE customer_id IS NOT NULL
  AND customer_id != '';
```

**c) Rule-based screening** – derives `residual_income`, `screening_status` and `reject_reason`.

```sql
SELECT
    customer_id, age, gender, employment_status,
    monthly_income, loan_amount, emi,
    (monthly_income - emi) AS residual_income,
    credit_score_origination AS credit_score,
    dti,
    revolving_utilization_origination AS revolving_utilization,
    credit_inquiries_12m,
    deterioration_pattern,

    CASE
        WHEN dti > 0.50 OR revolving_utilization_origination > 0.85 THEN 'Rejected'
        WHEN credit_inquiries_12m >= 4
         AND LOWER(deterioration_pattern) = 'credit_seeking'        THEN 'Rejected'
        WHEN (monthly_income - emi) < 8000                          THEN 'Rejected'
        ELSE 'Passed'
    END AS screening_status,

    CASE
        WHEN dti > 0.50 THEN 'High DTI Burden (>50%)'
        WHEN revolving_utilization_origination > 0.85 THEN 'High Credit Utilization (>85%)'
        WHEN credit_inquiries_12m >= 4
         AND LOWER(deterioration_pattern) = 'credit_seeking' THEN 'Credit Seeking Behavior'
        WHEN (monthly_income - emi) < 8000 THEN 'Low Residual Income (<8,000 THB)'
        ELSE 'Eligible'
    END AS reject_reason
FROM raw_data_backup;
```

**d) Profile summary** – applicants grouped by `employment_status` × `deterioration_pattern`, with `total_applicants`, `total_rejected`, `total_passed` and `reject_rate_pct`.

| employment_status | deterioration_pattern | total_applicants | total_rejected | total_passed | reject_rate_pct |
|---|---|---:|---:|---:|---:|
| employed | stable | 65,928 | 34,903 | 31,025 | 52.94 |
| self-employed | stable | 23,574 | 12,483 | 11,091 | 52.95 |
| employed | gradual_decline | 14,386 | 7,628 | 6,758 | 53.02 |
| employed | sudden_shock | 7,523 | 3,979 | 3,544 | 52.89 |
| employed | credit_seeking | 6,648 | 3,986 | 2,662 | 59.96 |
| self-employed | gradual_decline | 5,089 | 2,657 | 2,432 | 52.21 |
| unemployed | stable | 4,722 | 2,502 | 2,220 | 52.99 |
| self-employed | sudden_shock | 2,744 | 1,445 | 1,299 | 52.66 |
| self-employed | credit_seeking | 2,333 | 1,378 | 955 | 59.07 |
| unemployed | gradual_decline | 1,022 | 536 | 486 | 52.45 |
| unemployed | sudden_shock | 564 | 301 | 263 | 53.37 |
| unemployed | credit_seeking | 467 | 272 | 195 | 58.24 |

Across every employment type, the `credit_seeking` pattern shows a rejection rate roughly 6–7 percentage points above the other patterns.

### 2. Financial Impact Analysis

Screening results are translated from *headcount* into *monetary values* so finance teams can assess liquidity, forecast interest revenue and quantify the credit risk avoided.

```sql
SELECT
    CASE
        WHEN dti > 0.50 OR revolving_utilization_origination > 0.85 THEN 'Rejected'
        WHEN credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking' THEN 'Rejected'
        WHEN (monthly_income - emi) < 8000 THEN 'Rejected'
        ELSE 'Passed'
    END AS screening_status,
    COUNT(*)                                   AS total_applicants,
    SUM(loan_amount)                           AS total_loan_requested,
    ROUND(AVG(loan_amount), 2)                 AS avg_loan_amount,
    ROUND(SUM(loan_amount) / (SELECT SUM(loan_amount) FROM raw_data_backup) * 100, 2) AS portfolio_share_pct,
    ROUND(SUM(loan_amount * (interest_rate / 100)), 2) AS estimated_annual_interest_revenue
FROM raw_data_backup
GROUP BY screening_status;
```

| screening_status | total_applicants | total_loan_requested (THB) | avg_loan_amount (THB) | portfolio_share_pct | estimated_annual_interest_revenue (THB) |
|---|---:|---:|---:|---:|---:|
| Rejected | 72,070 | 3,630,123,000 | 50,369.40 | 49.94 | 436,453,381.20 |
| Passed | 62,930 | 3,639,276,885 | 57,830.56 | 50.06 | 436,596,041.40 |

**Takeaway:** approving the *Passed* portfolio lets the institution deploy capital efficiently with a predictable ~436.6M THB annual interest stream, while declining the *Rejected* segment avoids exposing ~3.63B THB of requested credit to high-risk borrowers and reduces future NPL exposure.

### 3. Segment & Reject Reason Matrix

Counts the number of applicants triggering each red flag per employment segment. A single applicant can trigger several rules, so the reason counts are **not mutually exclusive**.

| employment_status | total_applicants | high_dti | high_utilization | credit_seeking | low_residual_income | segment_reject_rate_pct |
|---|---:|---:|---:|---:|---:|---:|
| employed | 94,485 | 3,657 | 31 | 971 | 48,256 | 53.44 |
| self-employed | 33,740 | 1,292 | 8 | 345 | 17,175 | 53.24 |
| unemployed | 6,775 | 237 | 2 | 75 | 3,462 | 53.30 |

**Takeaways**

- **Low residual income** is the dominant failure point in every segment (68,893 of 135,000 applicants, ≈51%).
- High DTI is the second most common trigger and is concentrated in employed applicants – an opportunity for a **debt consolidation** product.
- High revolving utilization is almost non-existent in this portfolio (41 applicants in total).

### 4. Machine Learning Models

**Goal:** automate the screening decision using two complementary models.

- **Features:** `age`, `employment_status` (one-hot encoded), `monthly_income`, `emi`, `dti`, `revolving_utilization`, `credit_inquiries_12m`, `residual_income`
- **Target:** `screening_status` (`Rejected = 1` is the positive class, `Passed = 0`)
- **Split:** 80/20 train–test, stratified, `random_state=42`
- **Logistic Regression:** trained on standardized features (`StandardScaler`)
- **XGBoost:** `n_estimators=200`, `max_depth=4`, `learning_rate=0.1`, `eval_metric="logloss"`

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier

RANDOM_STATE = 42
df = pd.read_csv("data/Result.csv")

FEATURE_COLS = ["age", "employment_status", "monthly_income", "emi", "dti",
                "revolving_utilization", "credit_inquiries_12m", "residual_income"]

model_df = df[FEATURE_COLS + ["screening_status"]].copy()
model_df["screening_status"] = model_df["screening_status"].map({"Passed": 0, "Rejected": 1})
model_df = pd.get_dummies(model_df, columns=["employment_status"], drop_first=True)

X = model_df.drop(columns=["screening_status"])
y = model_df["screening_status"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

log_reg = LogisticRegression(max_iter=1000, random_state=RANDOM_STATE).fit(X_train_scaled, y_train)
xgb_clf = XGBClassifier(n_estimators=200, max_depth=4, learning_rate=0.1,
                        eval_metric="logloss", random_state=RANDOM_STATE).fit(X_train, y_train)
```

---

## Results

### Model comparison

Evaluated on a test set of **200 applicants (90 Passed / 110 Rejected)**, with *Rejected* as the positive class.

| Model | Accuracy | Precision | Recall | F1-score |
|---|---:|---:|---:|---:|
| Logistic Regression | 0.93 | 0.91 | 0.96 | 0.93 |
| XGBoost | 1.00 | 1.00 | 1.00 | 1.00 |

### Confusion matrix

| | Logistic Regression | XGBoost |
|---|---|---|
| True Negative (Passed → Passed) | 79 | 90 |
| False Positive (Passed → Rejected) | 11 | 0 |
| False Negative (Rejected → Passed) | 4 | 0 |
| True Positive (Rejected → Rejected) | 106 | 110 |

- **False Positive** = an eligible customer wrongly rejected (lost interest revenue).
- **False Negative** = a high-risk customer wrongly approved (potential NPL exposure).

![Classification reports](images/logreg_classification_report.png)
![Confusion matrices](images/confusion_matrix.png)

### Key risk drivers

![Feature importance and coefficients](images/feature_importance.png)

- **XGBoost:** `residual_income` is by far the most important feature (> 80% gain), followed by `dti` and `credit_inquiries_12m`.
- **Logistic Regression:** `dti` and `emi` push applicants toward rejection (positive coefficients); `residual_income` and `monthly_income` push toward eligibility (negative coefficients, ≈ −3.0 for residual income).

### Why the two models differ

- The screening policy is built from **sharp threshold rules** (e.g. `dti > 0.50`, `residual_income < 8,000`). Tree-based models split the feature space on exactly this kind of cut-off, so XGBoost can reproduce the rules perfectly.
- Logistic Regression draws a smooth linear boundary, so it over-penalizes applicants close to the thresholds (11 false positives) and struggles with combined conditions such as *inquiries ≥ 4 AND credit-seeking* (4 false negatives).

---

## Recommendations

**1. Dual-model deployment**

- **Production decisioning – XGBoost:** serve the trained model behind a REST API for instant applicant screening; its alignment with the policy rules means no drift between model and policy.
- **Explainability & compliance – Logistic Regression:** use the standardized coefficients to document key risk drivers (`residual_income`, `dti`) for auditors, regulators and rejection explanations.

**2. Product & policy innovation**

- **Debt consolidation program:** for (e.g. 36 → 60 months) to reduce the monthly installment.
- **Credit line reduction / collateral:** for segments constrained by low disposable cash flow, consider an approved credit line reduction or collateral requirements to retain viable business instead of rejecting outright.

---

## Notes & Limitations

- **The ML target is derived from the screening rules.** The models learn to reproduce a deterministic policy rather than to predict actual default, so XGBoost's 1.00 score demonstrates rule replication, not predictive power on real-world defaults. A default-probability model would require observed repayment outcomes as the label.
- **Small evaluation set.** Metrics are reported on a 200-applicant test set; results on the full 135,000-record dataset should be validated before drawing production conclusions.
- **Reason counts overlap.** In the segment matrix, one applicant can trigger multiple red flags; counts should not be summed to obtain total rejections.
- Interest revenue is a simple estimate (`loan_amount × interest_rate`) and ignores tenor, amortization, fees and expected loss.

---

## Getting Started

### Prerequisites

- MySQL 8.x (or compatible)
- Python 3.9+

### Installation

```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
pip install -r requirements.txt
```

`requirements.txt`

```
pandas
numpy
matplotlib
seaborn
scikit-learn
xgboost
jupyter
```

### Run

1. Load the raw data into MySQL (`info.raw_data_1`).
2. Execute the scripts in `sql/` in order (backup → cleansing → screening → aggregations).
3. Export the screening query output to `data/Result.csv`.
4. Open `notebooks/classification_model.ipynb` and run all cells.

---

## Tech Stack

- **SQL (MySQL):** data backup, cleansing, rule-based screening, KPI aggregation
- **Python:** pandas, NumPy, scikit-learn, XGBoost
- **Visualization:** Matplotlib, Seaborn

---

## Data Source

Bank Customer payment behavior dataset.
