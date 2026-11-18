# 🛡️ Credit Risk, Underwriting & Delinquency Policy Analysis

This comprehensive technical report details the credit risk architecture, underwriting segmentation, delinquency distributions, revolving balance exposure, loss forecasting, and mitigation playbooks across the **10,293 monitored accounts** in the **Credit Card Analytics Platform**.

---

## 📑 Table of Contents

- [1. Credit Risk Architecture Mindmaps & System Framework](#1-credit-risk-architecture-mindmaps--system-framework)
  - [1.1 Comprehensive Credit Risk Topology (Mermaid)](#11-comprehensive-credit-risk-topology-mermaid)
  - [1.2 Portfolio Credit Exposure Mindmap (ASCII)](#12-portfolio-credit-exposure-mindmap-ascii)
- [2. Portfolio Exposure & Delinquency Summary](#2-portfolio-exposure--delinquency-summary)
- [3. Delinquency Risk Stratification & Cohort Analysis](#3-delinquency-risk-stratification--cohort-analysis)
  - [3.1 Delinquency by Card Category Tier](#31-delinquency-by-card-category-tier)
  - [3.2 Delinquency by Customer Occupational Cohort](#32-delinquency-by-customer-occupational-cohort)
  - [3.3 Delinquency by Credit Line Utilization Band](#33-delinquency-by-credit-line-utilization-band)
  - [3.4 Delinquency by Customer Income Tier](#34-delinquency-by-customer-income-tier)
- [4. Basel III & CECL Expected Loss (EL) Financial Modeling](#4-basel-iii--cecl-expected-loss-el-financial-modeling)
- [5. Production Implementation: Risk Scoring & Early Warning Sentries](#5-production-implementation-risk-scoring--early-warning-sentries)
  - [5.1 SQL Production Risk Scoring View](#51-sql-production-risk-scoring-view)
  - [5.2 Python Automated Delinquency Sentry Script](#52-python-automated-delinquency-sentry-script)
- [6. Tiered Collections Escalation & Intervention Playbook](#6-tiered-collections-escalation--intervention-playbook)
- [7. Portfolio Macro Stress Testing & Capital Adequacy Simulation](#7-portfolio-macro-stress-testing--capital-adequacy-simulation)
- [8. Document Navigation Hub](#8-document-navigation-hub)

---

## 🗺️ 1. Credit Risk Architecture Mindmaps & System Framework

### 1.1 Comprehensive Credit Risk Topology (Mermaid)

```mermaid
mindmap
  root((Credit Risk Architecture))
    Portfolio Exposure ($88.96M Limits)
      Performing Accounts (93.94% / 9,669 accts)
        Committed Lines ($83.51M)
        Revolving Balances ($11.28M)
        Average Utilization (27.2%)
      Delinquent Accounts (6.06% / 624 accts)
        Committed Lines ($5.45M)
        Drawn Overdue Balances ($703.8K)
        Average Utilization (28.1%)
    Risk Stratification Pillars
      Occupational Risk Corridor
        Government Staff: 7.27% Delinquent
        Self-Employed: 6.51% Delinquent
        Businessmen: 5.27% Delinquent (Prime)
      Utilization Corridors
        Healthy (<30%): 6,355 accounts
        Danger Corridor (30-50%): 6.64% Peak Default
        Elevated (50-70%): 5.71% Default
        Critical (>70%): 1,077 accounts (Line Cap)
      Card Tier Distribution
        Blue: 6.05% Default
        Silver: 6.16% Default
        Gold: 6.22% Default
        Platinum: 5.97% Default
    Regulatory Loss Modeling
      Basel III / CECL Framework
        Probability of Default (PD: 6.06%)
        Exposure at Default (EAD: $1.65M with CCF)
        Loss Given Default (LGD: 65%)
        Annual Expected Loss ($260,312 USD)
        Loss-to-Interest Ratio (3.26% Safety Buffer)
    Automated Mitigation Sentries
      Early Warning Triggers
        EWI 1: Utilization > 70% Spike
        EWI 2: Payment Missed (Day 0)
        EWI 3: CSS Drop < 2.5
      Collections Escalation
        Days 1-15: Push SMS & Fee Waiver
        Days 16-30: Outbound IVR & Soft Cap
        Days 31-60: Bureau Reporting & Hard Freeze
        Days 61-90+: Debt Workout EMI Plan
```

---

### 1.2 Portfolio Credit Exposure Mindmap (ASCII)

```
========================================================================================================================
                                     PORTFOLIO CREDIT RISK ARCHITECTURE & EXPOSURE
========================================================================================================================

                                            [*] TOTAL CREDIT PORTFOLIO ($88.96M LIMITS)
                                                                 |
                     +-------------------------------------------+-------------------------------------------+
                     |                                                                                       |
                     v                                                                                       v
     [PERFORMING ACCOUNTS: 93.94%]                                                           [DELINQUENT ACCOUNTS: 6.06%]
     - Total Accounts: 9,669                                                                 - Total Accounts: 624
     - Revolving Balance: $11,276,992 (94.13%)                                               - Revolving Balance: $703,753 (5.87%)
     - Committed Lines: $83,510,685 (93.88%)                                                 - Committed Lines: $5,445,691 (6.12%)
     - Average Utilization: 27.20%                                                           - Average Utilization: 28.10%
                     |                                                                                       |
                     +---> Underwriting Segmentation                                                         +---> Risk Migration Triggers
                     |     |-- Tier 1: Prime (Limit > $15K)                                                  |     |-- Early Warning: CSS < 2.5
                     |     |-- Tier 2: Near-Prime ($5K - $15K)                                               |     |-- Spike: Revolving Bal > 70%
                     |     \-- Tier 3: Subprime (< $5K)                                                      |     \-- Inactivity: > 45 days dormant
                     |                                                                                       |
                     v                                                                                       v
     [*] Credit Line Policy Engine                                                           [*] Collections & Intervention Playbook
     - Automated Credit Line Increases (CLI)                                                 - Day 1-15: Soft SMS & App Push Reminders
     - Risk-based Credit Line Decreases (CLD)                                                - Day 16-30: Outbound Collections Call
     - Proactive Line Restructuring for Transactors                                          - Day 31-60: Credit Bureau Reporting & Freeze
========================================================================================================================
```

---

## 📊 2. Portfolio Exposure & Delinquency Summary

Across all 10,293 monitored credit card accounts, credit exposure and default distributions are audited as follows:

```
+----------------------------------------------------------------------------------------------------------------------+
|                                   PORTFOLIO CREDIT RISK & EXPOSURE AUDIT                                             |
+--------------------------+-----------------------+-----------------------+-------------------+-----------------------+
| CREDIT RISK METRIC       | PERFORMING POOL (0)   | DELINQUENT POOL (1)   | TOTAL PORTFOLIO   | DELINQUENT PROPORTION |
+--------------------------+-----------------------+-----------------------+-------------------+-----------------------+
| Monitored Accounts       | 9,669 accounts        | 624 accounts          | 10,293 accounts   | 6.06% Default Rate    |
| Total Committed Limits   | $83,510,685.00        | $5,445,691.00         | $88,956,376.00    | 6.12% Total Lines     |
| Average Credit Limit     | $8,637 / account      | $8,727 / account      | $8,642 / account  | 101.0% of Avg Limit   |
| Drawn Revolving Balances | $11,276,992.00        | $703,753.00           | $11,980,745.00    | 5.87% Drawn Exposure  |
| Average Revolving Balance| $1,166 / account      | $1,128 / account      | $1,164 / account  | 96.7% of Avg Balance  |
| Annual Fees Collected    | $2,824,465.00         | $177,045.00           | $3,001,510.00     | 5.90% Fee Yield       |
| Net Interest Earned      | $7,503,696.00         | $478,784.00           | $7,982,480.00     | 6.00% Interest Yield  |
| Gross Revenue Generated  | $53,142,824.00        | $3,374,187.00         | $56,517,011.00    | 5.97% Revenue Share   |
| Average Utilization Ratio| 27.20%                | 28.10%                | 27.45%            | Healthy Transactors   |
+--------------------------+-----------------------+-----------------------+-------------------+-----------------------+
```

---

## 🔬 3. Delinquency Risk Stratification & Cohort Analysis

### 3.1 Delinquency by Card Category Tier

Default rates remain relatively uniform across product categories, confirming that high-income tiers and premium cards require active risk controls just like mass cards:

```
+------------------------------------------------------------------------------------------------------+
|                                   DELINQUENCY BY CARD PRODUCT TIER                                   |
+------------+--------------------+--------------------+--------------------+--------------------------+
| CARD TIER  | TOTAL ACCOUNTS     | DELINQUENT COUNT   | DELINQUENCY RATE % | TOTAL REVENUE SHARE      |
+------------+--------------------+--------------------+--------------------+--------------------------+
| Blue       | 9,384 accounts     | 568 accounts       | 6.05%              | $47,188,612 (83.49%)     |
| Silver     | 649 accounts       | 40 accounts        | 6.16%              | $5,659,109 (10.01%)      |
| Gold       | 193 accounts       | 12 accounts        | 6.22%              | $2,533,682 (4.48%)       |
| Platinum   | 67 accounts        | 4 accounts         | 5.97%              | $1,135,608 (2.01%)       |
+------------+--------------------+--------------------+--------------------+--------------------------+
```

---

### 3.2 Delinquency by Customer Occupational Cohort

Occupational analysis uncovers critical risk disparities across customer employment sectors:

```
+------------------------------------------------------------------------------------------------------+
|                              OCCUPATIONAL RISK & DELINQUENCY MATRIX                                  |
+--------------------+--------------------+--------------------+-------------------+-------------------+
| OCCUPATION         | TOTAL ACCOUNTS     | DELINQUENT COUNT   | DELINQUENCY RATE% | GROSS REVENUE ($) |
+--------------------+--------------------+--------------------+-------------------+-------------------+
| Government Staff   | 1,554 accounts     | 113 accounts       | 7.27% 🔴 (High)   | $8,337,908.41     |
| Self-Employed      | 2,628 accounts     | 171 accounts       | 6.51% 🔴 (High)   | $8,542,544.75     |
| Blue-Collar        | 1,606 accounts     | 98 accounts        | 6.10% 🟡 (Mod)    | $7,038,775.12     |
| White-Collar       | 1,564 accounts     | 94 accounts        | 6.01% 🟡 (Mod)    | $10,277,159.23    |
| Retirees           | 1,006 accounts     | 46 accounts        | 4.57% 🟢 (Low)    | $4,622,342.34     |
| Businessman        | 1,935 accounts     | 102 accounts       | 5.27% 🟢 (Prime)  | $17,698,280.96    |
+--------------------+--------------------+--------------------+-------------------+-------------------+
```

#### Strategic Takeaway:
- **Government Employees**: Display the highest delinquency rate (**7.27%**). Though income is stable, debt servicing lags during seasonal spending peaks.
- **Self-Employed**: Volatile monthly cash flows lead to elevated defaults (**6.51%**), requiring automated payment grace extensions and SMS reminder triggers.
- **Businessmen**: Represents the portfolio's financial anchor: **$17.70M in revenue** with an exemplary **5.27% default rate**.

---

### 3.3 Delinquency by Credit Line Utilization Band

```
+------------------------------------------------------------------------------------------------------+
|                                   DELINQUENCY BY UTILIZATION CORRIDOR                                |
+--------------------+--------------------+--------------------+---------------------------------------+
| UTILIZATION BAND   | TOTAL ACCOUNTS     | DELINQUENT COUNT   | DEFAULT RATE % & BEHAVIORAL PROFILE   |
+--------------------+--------------------+--------------------+---------------------------------------+
| < 30% (Healthy)    | 6,355 accounts     | 397 accounts       | 6.25% (Everyday transactors)          |
| 30% - 50% (Danger) | 1,355 accounts     | 90 accounts        | 6.64% 🔴 (Peak Risk Corridor)         |
| 50% - 70% (Elevated| 1,506 accounts     | 86 accounts        | 5.71% (Revolving debt carriers)       |
| > 70% (Critical)   | 1,077 accounts     | 51 accounts        | 4.74% ⚠️ (Requires credit line freeze)|
+--------------------+--------------------+--------------------+---------------------------------------+
```

---

### 3.4 Delinquency by Customer Income Tier

- **Low Income (< $35K)**: 4,064 accounts | **252 delinquent (6.20%)**. Primarily non-discretionary utility bill cash squeezes.
- **Medium Income ($35K–$70K)**: 3,201 accounts | **179 delinquent (5.59%)**. The most financially resilient cohort.
- **High Income ($70K+)**: 3,028 accounts | **193 delinquent (6.37%)**. Driven by high-limit working capital utilization among entrepreneurs.

---

## 🧮 4. Basel III & CECL Expected Loss (EL) Financial Modeling

Under regulatory banking frameworks (**Basel III** and **CECL - Current Expected Credit Losses**), capital requirements and expected loan write-offs are quantified as:

$$\text{Expected Loss (EL)} = \text{PD} \times \text{EAD} \times \text{LGD}$$

```
+------------------------------------------------------------------------------------------------------+
|                                    BASEL III LOSS PARAMETER DERIVATION                               |
+--------------------------+-----------------------+---------------------------------------------------+
| PARAMETER                | CALCULATED VALUE      | DERIVATION & ECONOMIC BENCHMARK                   |
+--------------------------+-----------------------+---------------------------------------------------+
| Probability of Default   | 6.06% (0.0606)        | 624 delinquent accounts / 10,293 total accounts   |
| (PD)                     |                       |                                                   |
+--------------------------+-----------------------+---------------------------------------------------+
| Exposure at Default      | $1,652,141.00         | Delinquent Drawn Balance ($703,753) +             |
| (EAD)                    |                       | (20% Credit Conversion Factor * $4,741,938 Line)  |
+--------------------------+-----------------------+---------------------------------------------------+
| Loss Given Default       | 65.00% (0.65)         | Unsecured consumer credit industry benchmark;     |
| (LGD)                    |                       | reflects 35% salvage post-workout collections     |
+--------------------------+-----------------------+---------------------------------------------------+
| Quarterly Expected Loss  | $65,078.00            | Expected credit loss per 3-month operating cycle  |
+--------------------------+-----------------------+---------------------------------------------------+
| Annual Expected Loss     | $260,312.00           | $65,078 * 4 quarters                              |
+--------------------------+-----------------------+---------------------------------------------------+
```

### Safety Margin Evaluation:
$$\frac{\text{Annual Expected Loss}}{\text{Annual Net Interest Income}} = \frac{\$260,312}{\$7,982,480} = \mathbf{3.26\%}$$

The portfolio's expected credit loss consumes only **3.26% of net interest earnings**, proving that portfolio interest yield ($7.98M) comfortably insulates the bank against default shocks.

---

## 💻 5. Production Implementation: Risk Scoring & Early Warning Sentries

### 5.1 SQL Production Risk Scoring View

This SQL view computes multi-factor risk scores and flags accounts requiring immediate collections intervention:

```sql
CREATE OR REPLACE VIEW view_high_risk_delinquency_sentry AS
SELECT 
    cc.Client_Num,
    c.Customer_Job,
    c.Income,
    cc.Card_Category,
    cc.Credit_Limit,
    cc.Total_Revolving_Bal,
    ROUND(cc.Avg_Utilization_Ratio * 100, 2) AS utilization_pct,
    cc.Delinquent_Acc,
    c.Cust_Satisfaction_Score,
    -- Multi-Factor Early Warning Risk Score (0 to 100)
    ROUND(
        (CASE WHEN cc.Delinquent_Acc = 1 THEN 40 ELSE 0 END) +
        (CASE WHEN cc.Avg_Utilization_Ratio > 0.70 THEN 30
              WHEN cc.Avg_Utilization_Ratio > 0.50 THEN 15 ELSE 0 END) +
        (CASE WHEN c.Customer_Job IN ('Govt', 'Selfemployeed') THEN 15 ELSE 5 END) +
        (CASE WHEN c.Cust_Satisfaction_Score <= 2 THEN 15 ELSE 0 END),
        2
    ) AS credit_risk_score,
    CASE 
        WHEN cc.Delinquent_Acc = 1 AND cc.Avg_Utilization_Ratio > 0.70 THEN 'CRITICAL: Hard Freeze'
        WHEN cc.Delinquent_Acc = 1 THEN 'ACTION: Collections Outreach'
        WHEN cc.Avg_Utilization_Ratio > 0.70 THEN 'WARNING: Soft Limit Cap'
        ELSE 'STANDARD: Performing'
    END AS risk_action_recommendation
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num
WHERE cc.Delinquent_Acc = 1 OR cc.Avg_Utilization_Ratio > 0.70
ORDER BY credit_risk_score DESC, cc.Total_Revolving_Bal DESC;
```

---

### 5.2 Python Automated Delinquency Sentry Script

This script scans active accounts and triggers operational alerts when early warning risk thresholds are breached:

```python
"""
Automated Early Warning Credit Risk Sentry
"""
import csv
import sys

def evaluate_portfolio_risk(csv_file_path):
    print("Executing automated credit risk scan...")
    high_risk_accounts = []
    
    with open(csv_file_path, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            client_num = row['Client_Num']
            delinquent = int(row['Delinquent_Acc'])
            utilization = float(row['Avg_Utilization_Ratio'])
            revolving_bal = float(row['Total_Revolving_Bal'])
            
            # Risk Trigger: Delinquent or Utilization > 80%
            if delinquent == 1 or utilization > 0.80:
                high_risk_accounts.append({
                    'Client_Num': client_num,
                    'Delinquent': delinquent,
                    'Utilization': utilization,
                    'Revolving_Bal': revolving_bal
                })
                
    print(f"Total High-Risk Accounts Identified: {len(high_risk_accounts)}")
    return high_risk_accounts

if __name__ == "__main__":
    evaluate_portfolio_risk("credit_card.csv")
```

---

## 🚨 6. Tiered Collections Escalation & Intervention Playbook

```
+----------------------------------------------------------------------------------------------------------------------+
|                                   COLLECTIONS ESCALATION WORKFLOW                                                    |
+--------------------+----------------------------------+--------------------------------------------------------------+
| ESCALATION STAGE   | ACCOUNT STATUS                   | OPERATIONAL INTERVENTION PROTOCOL                            |
+--------------------+----------------------------------+--------------------------------------------------------------+
| Stage 1            | 1 to 15 Days Past Due            | - Push in-app payment reminder and SMS payment link.         |
| (Soft Reminder)    | (Early Grace Period)             | - Offer automated late-fee waiver if paid within 48 hours.   |
+--------------------+----------------------------------+--------------------------------------------------------------+
| Stage 2            | 16 to 30 Days Past Due           | - Initiate automated outbound conversational IVR.             |
| (Line Constraint)  | (Moderate Delinquency)           | - Apply soft authorization limit ($100 cap per swipe).       |
+--------------------+----------------------------------+--------------------------------------------------------------+
| Stage 3            | 31 to 60 Days Past Due           | - Execute hard card spending freeze across all POS channels. |
| (Credit Freeze)    | (Serious Delinquency)            | - Report delinquency to credit bureaus (Equifax, Experian).  |
|                    |                                  | - Transfer account to dedicated internal recovery unit.      |
+--------------------+----------------------------------+--------------------------------------------------------------+
| Stage 4            | 61 to 90+ Days Past Due          | - Offer fixed 24-month debt restructuring loan at 9.9% APR.  |
| (Restructuring/CO) | (Pre-Charge-Off Workout)         | - If uncooperative, initiate charge-off and legal recovery.  |
+--------------------+----------------------------------+--------------------------------------------------------------+
```

---

## 📊 7. Portfolio Macro Stress Testing & Capital Adequacy Simulation

```
+------------------------------------------------------------------------------------------------------+
|                                 MACROECONOMIC STRESS TEST SCENARIOS                                  |
+--------------------+--------------------+--------------------+-------------------+-------------------+
| SCENARIO NAME      | DELINQUENCY SHOCK  | PROJECTED DEFAULTS | CAPITAL IMPACT    | BUFFER EVALUATION |
+--------------------+--------------------+--------------------+-------------------+-------------------+
| Baseline FY 2023   | 6.06% Delinquency  | $260,312 Loss      | $7.98M Interest   | 🟢 30.6x Coverage |
| Mild Recession     | 8.50% Delinquency  | $365,000 Loss      | $7.40M Interest   | 🟢 20.2x Coverage |
| Severe Downturn    | 12.00% Delinquency | $515,000 Loss      | $6.80M Interest   | 🟢 13.2x Coverage |
+--------------------+--------------------+--------------------+-------------------+-------------------+
```

---

## 📌 8. Document Navigation Hub

| Document | Focus Area | Direct File Link |
| :--- | :--- | :--- |
| 📘 **Project Explanation** | Technical architecture & commercial banking economics | [`docs/PROJECT_EXPLANATION.md`](PROJECT_EXPLANATION.md) |
| 🔄 **Project Flow** | 10 Execution diagrams & decision lifecycles | [`docs/PROJECT_FLOW.md`](PROJECT_FLOW.md) |
| 📊 **Project Presentation** | 12-Slide executive deck briefing with notes | [`docs/PROJECT_PRESENTATION.md`](PROJECT_PRESENTATION.md) |
| 📈 **Business Insights** | Demographic spending cohorts & geographic findings | [`docs/BUSINESS_INSIGHTS_REPORT.md`](BUSINESS_INSIGHTS_REPORT.md) |
| 📄 **Data Dictionary** | 10,293 account schema definitions & constraints | [`docs/DATA_DICTIONARY.md`](DATA_DICTIONARY.md) |
| 📐 **DAX Measures** | Complete DAX measure catalog with variable scoping | [`docs/DAX_MEASURES.md`](DAX_MEASURES.md) |
| 🖥️ **Power BI Guide** | Pixel-perfect canvas coordinates & formatting rules | [`docs/POWER_BI_DASHBOARD_GUIDE.md`](POWER_BI_DASHBOARD_GUIDE.md) |
| 🔄 **Power Query M Code** | Full M expressions, schema drift resolvers & calendar | [`docs/ETL_POWER_QUERY_M_CODE.md`](ETL_POWER_QUERY_M_CODE.md) |
| 🚀 **Marketing Playbook** | 14-day activation funnels & digital channel shift | [`docs/MARKETING_AND_PORTFOLIO_OPTIMIZATION.md`](MARKETING_AND_PORTFOLIO_OPTIMIZATION.md) |
| 🎙️ **Interview & Case Study** | STAR project defense & 15+ technical interview Q&A | [`docs/INTERVIEW_QA_AND_PORTFOLIO_CASE_STUDY.md`](INTERVIEW_QA_AND_PORTFOLIO_CASE_STUDY.md) |
| 🧪 **Data Validation Report**| Official 31-point mathematical reconciliation report | [`docs/DATA_VALIDATION_REPORT.md`](DATA_VALIDATION_REPORT.md) |
| 🛠️ **SQL Pipeline** | Production PostgreSQL DDL, staging tables & views | [`docs/SQL_SCRIPTS.sql`](SQL_SCRIPTS.sql) |
| 📖 **Master README** | Master repository overview & setup instructions | [`README.md`](../README.md) |
