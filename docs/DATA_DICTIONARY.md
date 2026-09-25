# Data Dictionary: Credit Card Financial & Customer Analytics

This document provides a comprehensive specification of the data tables, fields, types, constraints, and business logic utilized in the **Credit Card Financial Dashboard** project.

---

## 1. Overview of Data Sources

The project utilizes two primary data entities collected across 53 weeks of the fiscal year 2023:
1. **Transaction & Credit Performance (`credit_card.csv`, `cc_add.csv`)**: Captures account-level weekly activity, spending behavior, credit line usage, interest accrued, fees, and delinquency status.
2. **Customer Demographics & Profiles (`customer.csv`, `cust_add.csv`)**: Captures customer personal information, socioeconomic attributes, employment, asset ownership, and customer satisfaction ratings.

### File Manifest & Record Counts

| File Name | Description | Ingestion Phase | Record Count | Column Count |
| :--- | :--- | :--- | :--- | :--- |
| `credit_card.csv` | Historical transaction & card performance data (Weeks 1–52) | Initial Load | 10,108 | 18 |
| `customer.csv` | Customer demographics & socioeconomic profiles | Initial Load | 10,108 | 15 |
| `cc_add.csv` | Supplemental transaction data (Week 53 / Year-End) | Incremental Load | 185 | 18 |
| `cust_add.csv` | Supplemental customer profile data (Week 53 / Year-End) | Incremental Load | 185 | 15 |
| **Consolidated Total** | Full-year integrated analytics dataset | Production View | **10,293** | **33** |

---

## 2. Table Schema: `credit_card` (Transaction & Performance Data)

**Primary Key / Joining Key**: `Client_Num`  
**Temporal Coverage**: 01-01-2023 to 31-12-2023 (Weeks 1 to 53)

| Column Name | Data Type | Nullable | Example Values | Description & Business Definition |
| :--- | :--- | :--- | :--- | :--- |
| `Client_Num` | `BIGINT` | No | `708082083`, `963607849` | Unique 9-digit account/client identification number. Primary link to `customer` table. |
| `Card_Category` | `VARCHAR(20)` | No | `Blue`, `Silver`, `Gold`, `Platinum` | Credit card tier held by the client. Dictates reward structures, credit limits, and fee schedule. |
| `Annual_Fees` | `DECIMAL(10,2)` | No | `0.00`, `140.00`, `495.00` | Annual membership fee charged to the cardholder account in USD. |
| `Activation_30_Days` | `TINYINT` | No | `0`, `1` | Binary flag indicating if the card was activated within 30 days of issuance (`1` = Yes, `0` = No). |
| `Customer_Acq_Cost` | `DECIMAL(10,2)` | No | `72.00`, `96.00`, `150.00` | Customer Acquisition Cost (CAC) incurred by the bank to acquire the client in USD. |
| `Week_Start_Date` | `DATE` / `VARCHAR` | No | `01-01-2023`, `31-12-2023` | Calendar date marking the beginning of the reporting week (DD-MM-YYYY format). |
| `Week_Num` | `VARCHAR(10)` | No | `Week-1`, `Week-28`, `Week-53` | Standardized fiscal week label (Weeks 1 to 53). |
| `Qtr` | `VARCHAR(5)` | No | `Q1`, `Q2`, `Q3`, `Q4` | Fiscal calendar quarter corresponding to the transaction period. |
| `current_year` | `INT` | No | `2023` | Fiscal calendar year of the record. |
| `Credit_Limit` | `DECIMAL(12,2)` | No | `1438.30`, `8258.00`, `34516.00` | Total maximum credit line extended to the client in USD. |
| `Total_Revolving_Bal` | `DECIMAL(12,2)` | No | `0.00`, `690.00`, `2517.00` | Outstanding balance carried over from previous billing cycles in USD. |
| `Total_Trans_Amt` | `DECIMAL(12,2)` | No | `992.00`, `3940.00`, `15149.00` | Total monetary spend volume transacted by the cardholder during the period in USD. |
| `Total_Trans_Vol` / `Total_Trans_Ct` | `INT` | No | `21`, `56`, `111` | Total count of settled transactions executed by the cardholder in the reporting period. |
| `Avg_Utilization_Ratio` | `DECIMAL(6,4)` | No | `0.0000`, `0.2745`, `0.7360` | Average credit card utilization ratio (`Total_Revolving_Bal / Credit_Limit`). Ranges from `0.0` to `1.0`. |
| `Use Chip` | `VARCHAR(15)` | No | `Swipe`, `Chip`, `Online` | Dominant point-of-sale interaction method or transaction authentication mechanism. |
| `Exp Type` | `VARCHAR(30)` | No | `Bills`, `Entertainment`, `Fuel`, `Grocery`, `Food`, `Travel` | Primary category of consumer expenditure. |
| `Interest_Earned` | `DECIMAL(10,2)` | No | `69.44`, `236.40`, `4393.21` | Net interest earned by the banking institution from financing revolving balances in USD. |
| `Delinquent_Acc` | `TINYINT` | No | `0`, `1` | Binary flag identifying if the account is delinquent (past-due/default status) (`1` = Delinquent, `0` = In Good Standing). |

---

## 3. Table Schema: `customer` (Demographics & Profiles)

**Primary Key / Joining Key**: `Client_Num`

| Column Name | Data Type | Nullable | Example Values | Description & Business Definition |
| :--- | :--- | :--- | :--- | :--- |
| `Client_Num` | `BIGINT` | No | `708082083`, `963607849` | Unique 9-digit account/client identification number. Foreign key to `credit_card`. |
| `Customer_Age` | `INT` | No | `24`, `42`, `62` | Age of cardholder in completed years. |
| `Gender` | `CHAR(1)` | No | `M`, `F` | Self-reported gender of the customer (`M` = Male, `F` = Female). |
| `Dependent_Count` | `INT` | No | `0`, `1`, `3`, `5` | Total number of financial dependents supported by the cardholder. |
| `Education_Level` | `VARCHAR(30)` | No | `Graduate`, `High School`, `Uneducated`, `Post-Graduate`, `Doctorate`, `Unknown` | Highest level of formal education completed. |
| `Marital_Status` | `VARCHAR(20)` | No | `Married`, `Single`, `Unknown`, `Divorced` | Current legal marital status of the customer. |
| `state_cd` | `CHAR(2)` | No | `TX`, `NY`, `CA`, `FL`, `NJ` | Two-letter US state postal abbreviation of primary residence. |
| `Zipcode` | `VARCHAR(10)` | No | `91750` | Postal residential zip code. |
| `Car_Owner` | `VARCHAR(5)` | No | `yes`, `no` | Vehicle ownership status. |
| `House_Owner` | `VARCHAR(5)` | No | `yes`, `no` | Home/real estate ownership status. |
| `Personal_loan` | `VARCHAR(5)` | No | `yes`, `no` | Flag indicating whether the customer maintains an active personal loan with the institution. |
| `contact` | `VARCHAR(20)` | No | `cellular`, `telephone`, `unknown` | Preferred communication/contact channel. |
| `Customer_Job` | `VARCHAR(30)` | No | `Businessman`, `White-collar`, `Selfemployeed`, `Govt`, `Blue-collar`, `Retirees` | Primary occupational classification or employment category. |
| `Income` | `DECIMAL(12,2)` | No | `14235.00`, `45683.00`, `202326.00` | Annual gross customer income in USD. |
| `Cust_Satisfaction_Score` | `INT` | No | `1`, `2`, `3`, `4`, `5` | Customer satisfaction rating (CSS) on a standardized 1 to 5 scale (1 = Poor, 5 = Excellent). |

---

## 4. Derived Metrics & Financial Logic

### A. Total Revenue Formula
In this financial model, institutional revenue generated by credit card operations is defined as the sum of cardholder fees, transaction fees/spend, and interest earned:

$$\text{Revenue} = \text{Annual\_Fees} + \text{Total\_Trans\_Amt} + \text{Interest\_Earned}$$

- **Annual Fees ($3.00M)**: Direct recurring subscription/membership revenue.
- **Transaction Amount ($45.53M)**: Gross transaction settlement and interchange base.
- **Interest Earned ($7.98M)**: Net financing revenue from revolving credit balances.
- **Total Portfolio Revenue**: **$56,517,011 (~$56.52M)**.

### B. Age Group Segmentation
Customers are categorized into five distinct demographic cohorts for targeted lifecycle marketing:
- `20-30`: Young Adults / Early Career ($1.07M Revenue, 220 accounts)
- `30-40`: Mid Career / Young Families ($9.84M Revenue, 1,876 accounts)
- `40-50`: Prime Earning Cohort ($24.73M Revenue, 4,606 accounts — **43.8% of portfolio**)
- `50-60`: Wealth Accumulation Cohort ($18.62M Revenue, 3,048 accounts — **32.9% of portfolio**)
- `60+`: Mature / Retirement Cohort ($2.25M Revenue, 543 accounts)

### C. Income Tier Classification
Income brackets are categorized into three socioeconomic tiers:
- **Lower Class**: Annual Income $< \$35,000$ (39.5% of accounts)
- **Middle Class**: Annual Income $\$35,000 - \$69,999$ (31.1% of accounts)
- **Upper Class**: Annual Income $\ge \$70,000$ (29.4% of accounts)

### D. Week-over-Week (WoW) Metrics
Used to track operational momentum between the final standard week (`Week-52`) and holiday peak (`Week-53`):
$$\text{WoW Growth} = \frac{\text{Metric}_{W53} - \text{Metric}_{W52}}{\text{Metric}_{W52}} \times 100$$
- **Revenue WoW Growth**: $+28.77\%$
- **Transaction Amount WoW Growth**: $+35.04\%$
- **Transaction Volume WoW Growth**: $+3.39\%$

---

## 5. Data Integrity & Constraints

1. **Entity Integrity**: `Client_Num` in `customer` has a 1-to-1 relationship with `Client_Num` in `credit_card`.
2. **Referential Integrity**: Every transaction record in `cc_add.csv` maps to a corresponding demographic profile in `cust_add.csv`.
3. **Domain Ranges**:
   - `Activation_30_Days`: $\{0, 1\}$
   - `Delinquent_Acc`: $\{0, 1\}$
   - `Cust_Satisfaction_Score`: $\{1, 2, 3, 4, 5\}$
   - `Avg_Utilization_Ratio`: $[0.000, 1.000]$
