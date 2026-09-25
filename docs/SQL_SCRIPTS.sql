-- ============================================================================
-- CREDIT CARD FINANCIAL DASHBOARD - SQL PIPELINE & ANALYTICAL SCRIPTS
-- RDBMS Compatibility: PostgreSQL / MySQL / SQL Server
-- Description: Complete DDL, Ingestion, Incremental Updates, and Validation Queries
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DATABASE CREATION
-- ----------------------------------------------------------------------------
CREATE DATABASE credit_card_db;
-- \c credit_card_db; -- In PostgreSQL or 'USE credit_card_db;' in MySQL

-- ----------------------------------------------------------------------------
-- 2. DDL - TABLE DEFINITIONS
-- ----------------------------------------------------------------------------

-- Table 1: Customer Demographics (cust_detail)
DROP TABLE IF EXISTS cust_detail CASCADE;
CREATE TABLE cust_detail (
    Client_Num BIGINT PRIMARY KEY,
    Customer_Age INT,
    Gender CHAR(1),
    Dependent_Count INT,
    Education_Level VARCHAR(50),
    Marital_Status VARCHAR(30),
    state_cd VARCHAR(10),
    Zipcode VARCHAR(20),
    Car_Owner VARCHAR(10),
    House_Owner VARCHAR(10),
    Personal_loan VARCHAR(10),
    contact VARCHAR(30),
    Customer_Job VARCHAR(50),
    Income DECIMAL(12, 2),
    Cust_Satisfaction_Score INT
);

-- Table 2: Credit Card Performance & Transactions (cc_detail)
DROP TABLE IF EXISTS cc_detail CASCADE;
CREATE TABLE cc_detail (
    Client_Num BIGINT,
    Card_Category VARCHAR(30),
    Annual_Fees DECIMAL(10, 2),
    Activation_30_Days INT,
    Customer_Acq_Cost DECIMAL(10, 2),
    Week_Start_Date DATE,
    Week_Num VARCHAR(20),
    Qtr VARCHAR(10),
    current_year INT,
    Credit_Limit DECIMAL(12, 2),
    Total_Revolving_Bal DECIMAL(12, 2),
    Total_Trans_Amt DECIMAL(12, 2),
    Total_Trans_Vol INT,
    Avg_Utilization_Ratio DECIMAL(8, 4),
    Use_Chip VARCHAR(30),
    Exp_Type VARCHAR(50),
    Interest_Earned DECIMAL(10, 2),
    Delinquent_Acc INT,
    CONSTRAINT fk_customer FOREIGN KEY (Client_Num) REFERENCES cust_detail(Client_Num)
);

-- Create Indexes for Optimal Query Performance
CREATE INDEX idx_cc_client ON cc_detail(Client_Num);
CREATE INDEX idx_cc_week ON cc_detail(Week_Num);
CREATE INDEX idx_cc_card ON cc_detail(Card_Category);
CREATE INDEX idx_cust_job ON cust_detail(Customer_Job);
CREATE INDEX idx_cust_state ON cust_detail(state_cd);

-- ----------------------------------------------------------------------------
-- 3. ETL - INITIAL DATA INGESTION (WEEKS 1 TO 52)
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

-- MySQL LOAD DATA INFILE Commands
/*
LOAD DATA LOCAL INFILE 'C:/path/to/customer.csv'
INTO TABLE cust_detail
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/path/to/credit_card.csv'
INTO TABLE cc_detail
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
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

-- Step 4.2: Append supplemental transaction data
COPY cc_detail
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

-- Query 5.2: Financial Performance by Card Category
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

-- Query 5.3: Revenue by Expenditure Category
SELECT 
    Exp_Type,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned), 2) AS revenue,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned) * 100.0 / 
          SUM(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned)) OVER(), 2) AS revenue_share_pct
FROM cc_detail
GROUP BY Exp_Type
ORDER BY revenue DESC;

-- Query 5.4: Transaction Channel & Authentication Method
SELECT 
    Use_Chip,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned), 2) AS revenue,
    SUM(Total_Trans_Vol) AS total_transactions,
    ROUND(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned) * 100.0 / 
          SUM(SUM(Annual_Fees + Total_Trans_Amt + Interest_Earned)) OVER(), 2) AS revenue_share_pct
FROM cc_detail
GROUP BY Use_Chip
ORDER BY revenue DESC;

-- Query 5.5: Top 5 States by Revenue Contribution
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

-- Query 5.6: Demographic Analysis by Customer Profession
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

-- Query 5.7: Week-over-Week (WoW) Comparison (Week 52 vs Week 53)
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
