# Power BI DAX Measures & Data Modeling Reference

This guide provides a comprehensive catalog of all Data Analysis Expressions (DAX) measures, calculated columns, and data modeling definitions implemented in the **Credit Card Financial Dashboard**.

---

## 1. Data Model Relationships

The Power BI data model establishes an active relationship between the demographic entity and the transaction entity:

```
+-----------------------------------+               +-----------------------------------+
|            cust_detail            |               |             cc_detail             |
+-----------------------------------+               +-----------------------------------+
| Client_Num (PK)                   | 1 -------- *  | Client_Num (FK)                   |
| Customer_Age                      |               | Card_Category                     |
| Gender                            |               | Annual_Fees                       |
| Education_Level                   |               | Total_Trans_Amt                   |
| Customer_Job                      |               | Total_Trans_Vol                   |
| Income                            |               | Interest_Earned                   |
| Cust_Satisfaction_Score           |               | Delinquent_Acc                    |
| state_cd                          |               | Week_Num                          |
+-----------------------------------+               +-----------------------------------+
```

- **Cardinality**: One-to-One / One-to-Many (`1 : *`)
- **Cross Filter Direction**: Both / Single (`cust_detail` filters `cc_detail`)

---

## 2. Calculated Columns

### 2.1 Total Account Revenue
Combines annual recurring membership fees, gross transaction amount, and interest accrued into a single row-level revenue metric:

```dax
Revenue = 'cc_detail'[Annual_Fees] + 'cc_detail'[Total_Trans_Amt] + 'cc_detail'[Interest_Earned]
```

### 2.2 Age Group Segmentation
Categorizes cardholders into actionable marketing age cohorts:

```dax
AgeGroup = 
SWITCH(
    TRUE(),
    'cust_detail'[Customer_Age] < 30, "20-30",
    'cust_detail'[Customer_Age] >= 30 && 'cust_detail'[Customer_Age] < 40, "30-40",
    'cust_detail'[Customer_Age] >= 40 && 'cust_detail'[Customer_Age] < 50, "40-50",
    'cust_detail'[Customer_Age] >= 50 && 'cust_detail'[Customer_Age] < 60, "50-60",
    'cust_detail'[Customer_Age] >= 60, "60+",
    "Unknown"
)
```

### 2.3 Income Class Segmentation
Segments customers into socio-economic income tiers corresponding to dashboard slicer buttons:

```dax
IncomeGroup = 
SWITCH(
    TRUE(),
    'cust_detail'[Income] < 35000, "lower class",
    'cust_detail'[Income] >= 35000 && 'cust_detail'[Income] < 70000, "Middle Class",
    'cust_detail'[Income] >= 70000, "Upper Class",
    "Unknown"
)
```

### 2.4 Numeric Week Number (Sorting & Time Intelligence)
Extracts the integer representation of `Week_Num` for accurate chronological sorting and lag calculations:

```dax
Week_Num_Int = VALUE(SUBSTITUTE('cc_detail'[Week_Num], "Week-", ""))
```

---

## 3. Core KPI Measures

### 3.1 Total Revenue
Calculates the aggregate financial revenue across all filtered dimensions:

```dax
Total_Revenue = SUM('cc_detail'[Revenue])
```
*Format: Currency (`$#,##0`), Display Units: Millions (`$57M` / `$56.52M`)*

### 3.2 Total Transaction Amount
Measures aggregate spend volume:

```dax
Total_Trans_Amount = SUM('cc_detail'[Total_Trans_Amt])
```
*Format: Currency (`$#,##0`), Display Units: Millions (`$46M` / `$45.53M`)*

### 3.3 Total Interest Earned
Tracks finance charges generated from revolving credit:

```dax
Total_Interest_Earned = SUM('cc_detail'[Interest_Earned])
```
*Format: Currency (`$#,##0`), Display Units: Millions (`$8M` / `$7.98M`)*

### 3.4 Total Transaction Count
Counts total completed card swipes, chip insertions, and online transactions:

```dax
Total_Trans_Count = SUM('cc_detail'[Total_Trans_Vol])
```
*Format: Whole Number (`#,##0`), Display Units: Thousands (`667K` / `667,234`)*

### 3.5 Total Customer Income
Measures aggregate earning power of the customer portfolio:

```dax
Total_Income = SUM('cust_detail'[Income])
```
*Format: Currency (`$#,##0`), Display Units: Millions (`$588M` / `$587.60M`)*

### 3.6 Average Customer Satisfaction Score (CSS)
Calculates overall customer sentiment index (1.00 to 5.00):

```dax
Average_CSS = AVERAGE('cust_detail'[Cust_Satisfaction_Score])
```
*Format: Decimal (`0.00`), Benchmark Value: `3.19`*

### 3.7 Portfolio Delinquency Rate
Computes the percentage of accounts currently marked delinquent:

```dax
Delinquency_Rate = 
DIVIDE(
    CALCULATE(COUNTROWS('cc_detail'), 'cc_detail'[Delinquent_Acc] = 1),
    COUNTROWS('cc_detail'),
    0
)
```
*Format: Percentage (`0.0%`), Benchmark Value: `6.06%`*

### 3.8 30-Day Card Activation Rate
Evaluates customer onboarding success within the first month of issuance:

```dax
Activation_Rate = 
DIVIDE(
    CALCULATE(COUNTROWS('cc_detail'), 'cc_detail'[Activation_30_Days] = 1),
    COUNTROWS('cc_detail'),
    0
)
```
*Format: Percentage (`0.0%`), Benchmark Value: `57.46%`*

---

## 4. Week-over-Week (WoW) Time Intelligence Measures

### 4.1 Current Week Revenue
Dynamically isolates revenue generated in the latest reporting week:

```dax
Current_Week_Revenue = 
VAR LatestWeek = MAX('cc_detail'[Week_Num_Int])
RETURN
CALCULATE(
    SUM('cc_detail'[Revenue]),
    FILTER(
        ALL('cc_detail'),
        'cc_detail'[Week_Num_Int] = LatestWeek
    )
)
```

### 4.2 Previous Week Revenue
Dynamically filters for revenue generated in the preceding week ($N - 1$):

```dax
Previous_Week_Revenue = 
VAR LatestWeek = MAX('cc_detail'[Week_Num_Int])
RETURN
CALCULATE(
    SUM('cc_detail'[Revenue]),
    FILTER(
        ALL('cc_detail'),
        'cc_detail'[Week_Num_Int] = LatestWeek - 1
    )
)
```

### 4.3 WoW Revenue Growth Rate
Computes percentage variation between consecutive weeks:

```dax
WoW_Revenue_Growth = 
DIVIDE(
    [Current_Week_Revenue] - [Previous_Week_Revenue],
    [Previous_Week_Revenue],
    0
)
```
*Format: Percentage (`+0.00%`), Week 53 vs 52 Benchmark: `+28.77%`*

### 4.4 Current vs Previous Week Transaction Amount & Growth
```dax
Current_Week_Trans_Amt = 
VAR LatestWeek = MAX('cc_detail'[Week_Num_Int])
RETURN
CALCULATE(
    SUM('cc_detail'[Total_Trans_Amt]),
    FILTER(ALL('cc_detail'), 'cc_detail'[Week_Num_Int] = LatestWeek)
)

Previous_Week_Trans_Amt = 
VAR LatestWeek = MAX('cc_detail'[Week_Num_Int])
RETURN
CALCULATE(
    SUM('cc_detail'[Total_Trans_Amt]),
    FILTER(ALL('cc_detail'), 'cc_detail'[Week_Num_Int] = LatestWeek - 1)
)

WoW_Trans_Amt_Growth = 
DIVIDE(
    [Current_Week_Trans_Amt] - [Previous_Week_Trans_Amt],
    [Previous_Week_Trans_Amt],
    0
)
```
*Week 53 vs 52 Benchmark: `+35.04%`*

---

## 5. Visual Formatting & Configuration Standards

| Visual Type | Target Metrics | Dimensions / Groupings |
| :--- | :--- | :--- |
| **Card (KPI)** | `Total_Revenue`, `Total_Interest_Earned`, `Total_Trans_Amount`, `Total_Trans_Count` | None (Global Context) |
| **Line & Clustered Column** | Column: `Revenue`, Line: `Total_Trans_Count` | Shared Axis: `Qtr` (Q1, Q2, Q3, Q4) |
| **Stacked Bar Chart** | `Revenue` | Axis: `Exp Type` (Bills, Entertainment, Fuel, Grocery, Food, Travel) |
| **Stacked Bar Chart** | `Revenue` | Axis: `Education_Level`, Legend: `Gender` |
| **Stacked Bar Chart** | `Revenue` | Axis: `Customer_Job`, Legend: `Gender` |
| **Bar / Donut Chart** | `Revenue` | Axis: `Card_Category` (Blue, Silver, Gold, Platinum) |
| **Stacked Bar Chart** | `Revenue` | Axis: `Use Chip` (Swipe, Chip, Online) |
| **Matrix Table** | `Revenue`, `Total_Trans_Amt`, `Interest_Earned` | Rows: `Card_Category` |
| **Matrix Table** | `Revenue`, `Total_Income`, `Dependent_Count` | Rows: `Customer_Job` |
