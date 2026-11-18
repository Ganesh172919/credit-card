-- ============================================================================
-- CREDIT CARD FINANCIAL DASHBOARD - SQL PIPELINE & ANALYTICAL SUITE
-- RDBMS Compatibility: PostgreSQL / MySQL / SQL Server / SQLite
-- Description: Complete DDL, Ingestion, Incremental Updates, and Analytical Views
-- ============================================================================

/*
====================================================================================================
                        SQL DATA PIPELINE & WAREHOUSE ARCHITECTURE MINDMAP
====================================================================================================

                               [*] RAW CSV FILES
                                       |
    +----------------------------------+----------------------------------+
    |                                                                     |
    v                                                                     v
[credit_card.csv / cc_add.csv]                               [customer.csv / cust_add.csv]
(Transaction & Account Feeds)                                 (Demographic & Socioeconomic Feeds)
    |                                                                     |
    +---> Ingestion: COPY / LOAD DATA                             +---> Ingestion: COPY / LOAD DATA
    |                                                                     |
    v                                                                     v
+-----------------------------+                               +-----------------------------+
|     cc_detail (STAGING)     |                               |    cust_detail (STAGING)    |
| - Client_Num (FK)           |                               | - Client_Num (PK)           |
| - Card_Category             |                               | - Customer_Age, Gender      |
| - Total_Trans_Amt / Vol     |                               | - Customer_Job, Income      |
| - Delinquent_Acc            |                               | - Cust_Satisfaction_Score   |
+-----------------------------+                               +-----------------------------+
    |                                                                     |
    \----------------------------------+----------------------------------/
                                       |
                                       v
                    +-------------------------------------+
                    |       RELATIONAL JOIN ENGINE        |
                    |   cc_detail.Client_Num =            |
                    |   cust_detail.Client_Num            |
                    +-------------------------------------+
                                       |
         +-----------------------------+-----------------------------+
         |                             |                             |
         v                             v                             v
  [FINANCIAL METRICS]           [RISK PROFILING]            [TIME INTELLIGENCE]
  - Total Portfolio Revenue     - Delinquency Rates         - Week 52 vs Week 53 WoW
  - Interchange Spend Volume    - Utilization Distribution  - Quarterly Seasonality
  - Revolving Interest Earned   - CSS by Card Tier          - Holiday Surge Analytics
====================================================================================================
*/

-- ----------------------------------------------------------------------------
-- 1. DATABASE CREATION
-- ----------------------------------------------------------------------------
CREATE DATABASE credit_card_db;
-- In PostgreSQL: \c credit_card_db;
-- In MySQL:      USE credit_card_db;

-- ----------------------------------------------------------------------------
-- 2. DDL - TABLE DEFINITIONS & CONSTRAINTS
-- ----------------------------------------------------------------------------

-- Table 1: Customer Demographics (cust_detail)
DROP TABLE IF EXISTS cust_detail CASCADE;
CREATE TABLE cust_detail (
    Client_Num BIGINT PRIMARY KEY,
    Customer_Age INT CHECK (Customer_Age BETWEEN 18 AND 110),
    Gender CHAR(1) CHECK (Gender IN ('M', 'F')),
    Dependent_Count INT CHECK (Dependent_Count >= 0),
    Education_Level VARCHAR(50),
    Marital_Status VARCHAR(30),
    state_cd VARCHAR(10),
    Zipcode VARCHAR(20),
    Car_Owner VARCHAR(10) CHECK (Car_Owner IN ('yes', 'no')),
    House_Owner VARCHAR(10) CHECK (House_Owner IN ('yes', 'no')),
    Personal_loan VARCHAR(10) CHECK (Personal_loan IN ('yes', 'no')),
    contact VARCHAR(30),
    Customer_Job VARCHAR(50),
    Income DECIMAL(12, 2) CHECK (Income >= 0),
    Cust_Satisfaction_Score INT CHECK (Cust_Satisfaction_Score BETWEEN 1 AND 5)
);

-- Table 2: Credit Card Performance & Transactions (cc_detail)
DROP TABLE IF EXISTS cc_detail CASCADE;
CREATE TABLE cc_detail (
    Client_Num BIGINT,
    Card_Category VARCHAR(30) CHECK (Card_Category IN ('Blue', 'Silver', 'Gold', 'Platinum')),
    Annual_Fees DECIMAL(10, 2) CHECK (Annual_Fees >= 0),
    Activation_30_Days INT CHECK (Activation_30_Days IN (0, 1)),
    Customer_Acq_Cost DECIMAL(10, 2) CHECK (Customer_Acq_Cost >= 0),
    Week_Start_Date DATE,
    Week_Num VARCHAR(20),
    Qtr VARCHAR(10) CHECK (Qtr IN ('Q1', 'Q2', 'Q3', 'Q4')),
    current_year INT CHECK (current_year = 2023),
    Credit_Limit DECIMAL(12, 2) CHECK (Credit_Limit > 0),
    Total_Revolving_Bal DECIMAL(12, 2) CHECK (Total_Revolving_Bal >= 0),
    Total_Trans_Amt DECIMAL(12, 2) CHECK (Total_Trans_Amt >= 0),
    Total_Trans_Vol INT CHECK (Total_Trans_Vol >= 0),
    Avg_Utilization_Ratio DECIMAL(8, 4) CHECK (Avg_Utilization_Ratio BETWEEN 0.0 AND 1.0),
    Use_Chip VARCHAR(30),
    Exp_Type VARCHAR(50),
    Interest_Earned DECIMAL(10, 2) CHECK (Interest_Earned >= 0),
    Delinquent_Acc INT CHECK (Delinquent_Acc IN (0, 1)),
    CONSTRAINT fk_customer FOREIGN KEY (Client_Num) REFERENCES cust_detail(Client_Num) ON DELETE CASCADE
);

-- Performance Optimization Indexes
CREATE INDEX idx_cc_client ON cc_detail(Client_Num);
CREATE INDEX idx_cc_week ON cc_detail(Week_Num);
CREATE INDEX idx_cc_card ON cc_detail(Card_Category);
CREATE INDEX idx_cc_delinquent ON cc_detail(Delinquent_Acc);
CREATE INDEX idx_cust_job ON cust_detail(Customer_Job);
CREATE INDEX idx_cust_state ON cust_detail(state_cd);

-- ----------------------------------------------------------------------------
-- 3. ETL - INITIAL INGESTION (WEEKS 1 TO 52)
-- ----------------------------------------------------------------------------

-- PostgreSQL COPY Commands
/*
COPY cust_detail(
    Client_Num, Customer_Age, Gender, Dependent_Count, Education_Level,
    Marital_Status, state_cd, Zipcode, Car_Owner, House_Owner,
    Personal_loan, contact, Customer_Job, Income, Cust_Satisfaction_Score
)
FROM 'C:/path/to/customer.csv'
DELIMITER ','
CSV HEADER;

COPY cc_detail(
    Client_Num, Card_Category, Annual_Fees, Activation_30_Days, Customer_Acq_Cost,
    Week_Start_Date, Week_Num, Qtr, current_year, Credit_Limit,
    Total_Revolving_Bal, Total_Trans_Amt, Total_Trans_Vol, Avg_Utilization_Ratio,
    Use_Chip, Exp_Type, Interest_Earned, Delinquent_Acc
)
FROM 'C:/path/to/credit_card.csv'
DELIMITER ','
CSV HEADER;
*/

-- ----------------------------------------------------------------------------
-- 4. INCREMENTAL DATA REFRESH (WEEK 53 DATA FEEDS)
-- ----------------------------------------------------------------------------

/*
-- Step 4.1: Append supplemental customer profiles
COPY cust_detail
FROM 'C:/path/to/cust_add.csv'
DELIMITER ','
CSV HEADER;

-- Step 4.2: Append supplemental transaction records
-- Note: 'cc_add.csv' column 'Total_Trans_Ct' is ingested into 'Total_Trans_Vol'
COPY cc_detail(
    Client_Num, Card_Category, Annual_Fees, Activation_30_Days, Customer_Acq_Cost,
    Week_Start_Date, Week_Num, Qtr, current_year, Credit_Limit,
    Total_Revolving_Bal, Total_Trans_Amt, Total_Trans_Vol, Avg_Utilization_Ratio,
    Use_Chip, Exp_Type, Interest_Earned, Delinquent_Acc
)
FROM 'C:/path/to/cc_add.csv'
DELIMITER ','
CSV HEADER;
*/

-- ----------------------------------------------------------------------------
-- 5. ANALYTICAL VALIDATION & KPI VERIFICATION QUERIES
-- ----------------------------------------------------------------------------

-- Query 5.1: Overall Portfolio Summary KPIs
SELECT 
    COUNT(DISTINCT c.Client_Num) AS total_customers,
    SUM(cc.Annual_Fees + cc.Total_Trans_Amt + cc.Interest_Earned) AS total_revenue,
    SUM(cc.Total_Trans_Amt) AS total_trans_amount,
    SUM(cc.Interest_Earned) AS total_interest_earned,
    SUM(cc.Annual_Fees) AS total_annual_fees,
    SUM(cc.Total_Trans_Vol) AS total_transactions,
    SUM(c.Income) AS total_customer_income,
    ROUND(AVG(c.Cust_Satisfaction_Score), 2) AS avg_satisfaction_score,
    ROUND(AVG(cc.Delinquent_Acc) * 100, 2) AS delinquency_rate_pct,
    ROUND(AVG(cc.Activation_30_Days) * 100, 2) AS activation_rate_pct,
    ROUND(AVG(cc.Customer_Acq_Cost), 2) AS avg_cac,
    ROUND(AVG(cc.Avg_Utilization_Ratio) * 100, 2) AS avg_utilization_pct
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num;

-- Query 5.2: Financial Breakdown by Card Tier
SELECT 
    Card_Category,
    COUNT(Client_Num) AS account_count,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned), 2) AS total_revenue,
    ROUND(SUM(Total_Trans_Amt), 2) AS total_trans_amount,
    ROUND(SUM(Interest_Earned), 2) AS total_interest_earned,
    SUM(Total_Trans_Vol) AS total_trans_count,
    ROUND(AVG(Credit_Limit), 2) AS avg_credit_limit,
    ROUND(AVG(Avg_Utilization_Ratio) * 100, 2) AS avg_utilization_pct,
    ROUND(AVG(Delinquent_Acc) * 100, 2) AS delinquency_rate_pct
FROM cc_detail
GROUP BY Card_Category
ORDER BY total_revenue DESC;

-- Query 5.3: Revenue Distribution by Expenditure Category
SELECT 
    Exp_Type,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned), 2) AS revenue,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned) * 100.0 / 
          SUM(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned)) OVER(), 2) AS revenue_share_pct
FROM cc_detail
GROUP BY Exp_Type
ORDER BY revenue DESC;

-- Query 5.4: Transaction Authentication Channel Mix
SELECT 
    TRIM(Use_Chip) AS authentication_channel,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned), 2) AS revenue,
    SUM(Total_Trans_Vol) AS total_transactions,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned) * 100.0 / 
          SUM(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned)) OVER(), 2) AS revenue_share_pct
FROM cc_detail
GROUP BY TRIM(Use_Chip)
ORDER BY revenue DESC;

-- Query 5.5: Geographic Performance (Top 5 States)
SELECT 
    c.state_cd,
    ROUND(SUM(cc.Annual_Fees + cc.Total_Trans_Amt + cc.Interest_Earned), 2) AS total_revenue,
    COUNT(DISTINCT c.Client_Num) AS customer_count,
    ROUND(AVG(c.Income), 2) AS avg_customer_income
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num
GROUP BY c.state_cd
ORDER BY total_revenue DESC
LIMIT 5;

-- Query 5.6: Occupational Risk & Earnings Matrix
SELECT 
    c.Customer_Job,
    ROUND(SUM(cc.Annual_Fees + cc.Total_Trans_Amt + cc.Interest_Earned), 2) AS total_revenue,
    SUM(c.Income) AS total_income,
    SUM(c.Dependent_Count) AS total_dependents,
    ROUND(AVG(c.Cust_Satisfaction_Score), 2) AS avg_css,
    ROUND(AVG(cc.Delinquent_Acc) * 100, 2) AS delinquency_rate_pct
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num
GROUP BY c.Customer_Job
ORDER BY total_revenue DESC;

-- Query 5.7: Week-over-Week (WoW) Momentum (Week 52 vs Week 53)
WITH weekly_summary AS (
    SELECT 
        Week_Num,
        SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned) AS revenue,
        SUM(Total_Trans_Amt) AS trans_amt,
        SUM(Total_Trans_Vol) AS trans_vol
    FROM cc_detail
    WHERE Week_Num IN ('Week-52', 'Week-53')
    GROUP BY Week_Num
)
SELECT 
    w52.revenue AS w52_revenue,
    w53.revenue AS w53_revenue,
    ROUND(((w53.revenue - w52.revenue) / w52.revenue) * 100, 2) AS wow_revenue_growth_pct,
    w52.trans_amt AS w52_trans_amt,
    w53.trans_amt AS w53_trans_amt,
    ROUND(((w53.trans_amt - w52.trans_amt) / w52.trans_amt) * 100, 2) AS wow_trans_amt_growth_pct,
    w52.trans_vol AS w52_trans_vol,
    w53.trans_vol AS w53_trans_vol,
    ROUND(((w53.trans_vol - w52.trans_vol) / w52.trans_vol) * 100, 2) AS wow_trans_vol_growth_pct
FROM 
    (SELECT * FROM weekly_summary WHERE Week_Num = 'Week-52') w52,
    (SELECT * FROM weekly_summary WHERE Week_Num = 'Week-53') w53;

-- Query 5.8: Early Delinquency Warning & High-Risk Portfolio Watchlist
SELECT 
    cc.Client_Num,
    c.Customer_Job,
    c.Income,
    cc.Card_Category,
    cc.Credit_Limit,
    cc.Total_Revolving_Bal,
    ROUND(cc.Avg_Utilization_Ratio * 100, 2) AS utilization_pct,
    cc.Delinquent_Acc
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num
WHERE cc.Avg_Utilization_Ratio > 0.70 OR cc.Delinquent_Acc = 1
ORDER BY cc.Total_Revolving_Bal DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- 6. AUTOMATED DATA QUALITY GATES & INTEGRITY AUDIT SUITE
-- ----------------------------------------------------------------------------
-- Verification queries executed upon initial and incremental ingestion:

-- Quality Gate 1: Check for Unlinked Transactions
SELECT COUNT(*) AS unlinked_records
FROM cc_detail cc
LEFT JOIN cust_detail c ON cc.Client_Num = c.Client_Num
WHERE c.Client_Num IS NULL;

-- Quality Gate 2: Check for Anomalous Negative Balances or Invalid Scores
SELECT COUNT(*) AS anomalous_records
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num
WHERE cc.Total_Trans_Amt < 0 
   OR cc.Interest_Earned < 0 
   OR c.Cust_Satisfaction_Score NOT BETWEEN 1 AND 5;

-- ----------------------------------------------------------------------------
-- 7. ANALYTICAL REPORTING VIEWS & PERFORMANCE INDEXING
-- ----------------------------------------------------------------------------

/*
====================================================================================================
                        SQL ANALYTICAL VIEW & INDEX TRAVERSAL MINDMAP
====================================================================================================

                               [*] ANALYTICAL QUERY OPTIMIZATION
                                               |
         +-------------------------------------+-------------------------------------+
         |                                                                           |
         v                                                                           v
[INDEX SEEK ACCELERATION]                                               [MATERIALIZED ANALYTIC MARTS]
- idx_cc_client: Instant FK join traversal                              - view_portfolio_executive_summary
- idx_cc_week: O(log N) week range isolation                            - view_weekly_momentum_kpis
- idx_cc_card: Card tier aggregation                                    - view_high_risk_delinquency_sentry
- idx_cust_job: Occupational risk grouping                                           |
         |                                                                           |
         +-------------------------------------+-------------------------------------+
                                               |
                                               v
                                [ASCII QUERY EXECUTION FLOW]
               Client_Num Filter ---> B-Tree Root Index Page
                                            |
                                            v (B-Tree Branch)
                                      Leaf Node Table Ptr
                                            |
                                            v
                                      Sequential Tuple Read
                                            |
                                            v
                                      Aggregate & Math Invariant Check
====================================================================================================
*/

-- View 7.1: Materialized Portfolio Executive Summary View
CREATE OR REPLACE VIEW view_portfolio_kpi_summary AS
SELECT 
    COUNT(DISTINCT c.Client_Num) AS total_accounts,
    SUM(cc.Annual_Fees + cc.Total_Trans_Amt + cc.Interest_Earned) AS gross_portfolio_revenue,
    SUM(cc.Total_Trans_Amt) AS gross_transaction_spend,
    SUM(cc.Interest_Earned) AS net_interest_earned,
    SUM(cc.Annual_Fees) AS total_annual_fees,
    SUM(cc.Total_Trans_Vol) AS total_transactions,
    ROUND(AVG(cc.Delinquent_Acc) * 100, 2) AS portfolio_delinquency_rate,
    ROUND(AVG(cc.Activation_30_Days) * 100, 2) AS card_activation_rate,
    ROUND(AVG(c.Cust_Satisfaction_Score), 2) AS avg_customer_satisfaction
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num;

