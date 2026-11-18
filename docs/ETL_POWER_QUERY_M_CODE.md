# 🔄 Power Query (M Code) ETL Data Pipeline Specification

This document provides the complete, production-ready **Power Query M formulas** required to ingest, clean, transform, normalize, and append the credit card transaction and customer datasets in Power BI Desktop or Excel.

---

## 🗺️ ETL Transformation Mindmap & Data Lineage

```
====================================================================================================
                        POWER QUERY ETL PIPELINE & RECONCILIATION FLOW
====================================================================================================

               [*] Source Directory Parameter: #"SourcePath" (c:\Users\RAVIPRAKASH\credit-card)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
[credit_card.csv] (Base W1-52)                              [customer.csv] (Base W1-52)
         |                                                         |
         v                                                         v
[cc_add.csv] (Inc Week 53)                                  [cust_add.csv] (Inc Week 53)
         |                                                         |
         +---> Normalize Schema Drift                              |
         |     \-- Rename: Total_Trans_Ct                          |
         |         -> Total_Trans_Vol                              |
         v                                                         v
   [Table.Combine]                                           [Table.Combine]
(Append cc_base + cc_add)                                 (Append cust_base + cust_add)
         |                                                         |
         +---> Data Cleansing & Type Enforcements                 +---> Data Cleansing & Type Enforcements
         |     |-- Trim Whitespace: "Use Chip", "Exp Type"         |     |-- Trim: Education, Marital, Job
         |     |-- Date Parsing: dd-MM-yyyy -> Date               |     |-- Numeric Casting: Income, Age
         |     |-- Integer: Client_Num, Delinquent, Vol            |     |-- Decimal: CSS (1.0 to 5.0)
         |     \-- Currency: Fees, Trans_Amt, Interest             \-- Boolean/Binary: Owner flags
         v                                                         v
+-------------------------------+                         +-------------------------------+
|     credit_card (Fact)        |                         |       customer (Dimension)    |
|   10,293 Rows / 18 Columns    |                         |   10,293 Rows / 15 Columns    |
+-------------------------------+                         +-------------------------------+
                                 \                       /
                                  \                     /
                                   v                   v
                                [*] Relational Star Schema Model
                                    (Join: Client_Num 1-to-1)
====================================================================================================
```

---

## ⚙️ Global Parameters (Power Query M)

### Parameter: `SourcePath`
Define a root path parameter to enable single-click migration across development, staging, and production environments.

```powerquery
let
    SourcePath = "c:\Users\RAVIPRAKASH\credit-card\" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
in
    SourcePath
```

---

## 📥 Fact Table: `credit_card` (Combined Transactions & Accounts)

This M expression loads `credit_card.csv`, loads `cc_add.csv`, renames mismatched headers (`Total_Trans_Ct` $\rightarrow$ `Total_Trans_Vol`), combines both row sets, strips trailing whitespace on `'Use Chip'` and `'Exp Type'`, parses European date strings (`dd-MM-yyyy`), and enforces strict datatypes.

```powerquery
let
    // Step 1: Ingest Base File (Weeks 1 to 52)
    Source_Base = Csv.Document(
        File.Contents(SourcePath & "credit_card.csv"),
        [Delimiter=",", Columns=18, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    Promoted_Headers_Base = Table.PromoteHeaders(Source_Base, [PromoteAllScalars=true]),

    // Step 2: Ingest Incremental File (Week 53 Refresh)
    Source_Add = Csv.Document(
        File.Contents(SourcePath & "cc_add.csv"),
        [Delimiter=",", Columns=18, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    Promoted_Headers_Add = Table.PromoteHeaders(Source_Add, [PromoteAllScalars=true]),

    // Step 3: Normalize Schema Drift (Resolve Column Header Mismatch)
    Renamed_Add_Columns = Table.RenameColumns(
        Promoted_Headers_Add,
        {{"Total_Trans_Ct", "Total_Trans_Vol"}},
        MissingField.Ignore
    ),

    // Step 4: Union / Append Datasets
    Combined_CC = Table.Combine({Promoted_Headers_Base, Renamed_Add_Columns}),

    // Step 5: Clean Whitespace on Categorical Dimensions
    Trimmed_Text = Table.TransformColumns(
        Combined_CC,
        {
            {"Use Chip", Text.Trim, type text},
            {"Exp Type", Text.Trim, type text},
            {"Card_Category", Text.Trim, type text},
            {"Week_Num", Text.Trim, type text},
            {"Qtr", Text.Trim, type text}
        }
    ),

    // Step 6: Parse Dates with Invariant Culture (dd-MM-yyyy format)
    Parsed_Dates = Table.TransformColumns(
        Trimmed_Text,
        {{"Week_Start_Date", each Date.FromText(_, "en-GB"), type date}}
    ),

    // Step 7: Enforce Strict Data Types
    Typed_Table = Table.TransformColumnTypes(
        Parsed_Dates,
        {
            {"Client_Num", Int64.Type},
            {"Card_Category", type text},
            {"Annual_Fees", Currency.Type},
            {"Activation_30_Days", Int64.Type},
            {"Customer_Acq_Cost", Currency.Type},
            {"Week_Start_Date", type date},
            {"Week_Num", type text},
            {"Qtr", type text},
            {"current_year", Int64.Type},
            {"Credit_Limit", Currency.Type},
            {"Total_Revolving_Bal", Currency.Type},
            {"Total_Trans_Amt", Currency.Type},
            {"Total_Trans_Vol", Int64.Type},
            {"Avg_Utilization_Ratio", type number},
            {"Use Chip", type text},
            {"Exp Type", type text},
            {"Interest_Earned", Currency.Type},
            {"Delinquent_Acc", Int64.Type}
        }
    ),

    // Step 8: Add Calculated Column: Total Account Revenue
    Added_Revenue = Table.AddColumn(
        Typed_Table,
        "Total_Revenue",
        each [Annual_Fees] + [Total_Trans_Amt] + [Interest_Earned],
        Currency.Type
    ),

    // Step 9: Add Calculated Column: Week Number Integer
    Added_Week_Int = Table.AddColumn(
        Added_Revenue,
        "Week_Num_Int",
        each Number.FromText(Text.AfterDelimiter([Week_Num], "-")),
        Int64.Type
    )
in
    Added_Week_Int
```

---

## 📥 Dimension Table: `customer` (Combined Demographics & Profiles)

This M expression loads `customer.csv` and `cust_add.csv`, appends them, trims all textual attributes, enforces data typing, and builds age/income group segmentations.

```powerquery
let
    // Step 1: Ingest Base Customer File
    Source_Cust_Base = Csv.Document(
        File.Contents(SourcePath & "customer.csv"),
        [Delimiter=",", Columns=15, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    Promoted_Cust_Base = Table.PromoteHeaders(Source_Cust_Base, [PromoteAllScalars=true]),

    // Step 2: Ingest Incremental Customer File
    Source_Cust_Add = Csv.Document(
        File.Contents(SourcePath & "cust_add.csv"),
        [Delimiter=",", Columns=15, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    Promoted_Cust_Add = Table.PromoteHeaders(Source_Cust_Add, [PromoteAllScalars=true]),

    // Step 3: Append Both Customer Tables
    Combined_Cust = Table.Combine({Promoted_Cust_Base, Promoted_Cust_Add}),

    // Step 4: Trim Whitespace
    Trimmed_Cust = Table.TransformColumns(
        Combined_Cust,
        {
            {"Gender", Text.Trim, type text},
            {"Education_Level", Text.Trim, type text},
            {"Marital_Status", Text.Trim, type text},
            {"state_cd", Text.Trim, type text},
            {"Customer_Job", Text.Trim, type text},
            {"contact", Text.Trim, type text}
        }
    ),

    // Step 5: Enforce Data Types
    Typed_Cust = Table.TransformColumnTypes(
        Trimmed_Cust,
        {
            {"Client_Num", Int64.Type},
            {"Customer_Age", Int64.Type},
            {"Gender", type text},
            {"Dependent_Count", Int64.Type},
            {"Education_Level", type text},
            {"Marital_Status", type text},
            {"state_cd", type text},
            {"Zipcode", Int64.Type},
            {"Car_Owner", type text},
            {"House_Owner", type text},
            {"Personal_loan", type text},
            {"contact", type text},
            {"Customer_Job", type text},
            {"Income", Currency.Type},
            {"Cust_Satisfaction_Score", type number}
        }
    ),

    // Step 6: Add Age Group Demographic Segmentation
    Added_Age_Group = Table.AddColumn(
        Typed_Cust,
        "Age_Group",
        each if [Customer_Age] < 30 then "20-30"
             else if [Customer_Age] < 40 then "30-40"
             else if [Customer_Age] < 50 then "40-50"
             else if [Customer_Age] < 60 then "50-60"
             else "60+",
        type text
    ),

    // Step 7: Add Income Tier Classification
    Added_Income_Group = Table.AddColumn(
        Added_Age_Group,
        "Income_Group",
        each if [Income] < 35000 then "Low (<$35K)"
             else if [Income] < 70000 then "Medium ($35K-$70K)"
             else "High ($70K+)",
        type text
    )
in
    Added_Income_Group
```

---

## 📅 Calendar Dimension Table: `Dim_Date` (M Script)

To ensure enterprise-grade time-intelligence without relying on implicit datetime hierarchies, generate this dynamic calendar table:

```powerquery
let
    // Define boundary dates
    StartDate = #date(2023, 1, 1),
    EndDate = #date(2023, 12, 31),
    NumberOfDays = Duration.Days(EndDate - StartDate) + 1,

    // Generate date sequence
    DateList = List.Dates(StartDate, NumberOfDays, #duration(1, 0, 0, 0)),
    TableFromList = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(TableFromList, {{"Date", type date}}),

    // Add analytical date attributes
    AddYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date]), Int64.Type),
    AddQuarterNumber = Table.AddColumn(AddYear, "QuarterNumber", each Date.QuarterOfYear([Date]), Int64.Type),
    AddQuarter = Table.AddColumn(AddQuarterNumber, "Quarter", each "Q" & Text.From([QuarterNumber]), type text),
    AddMonthNumber = Table.AddColumn(AddQuarter, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthNumber, "MonthName", each Date.ToText([Date], "MMMM"), type text),
    AddWeekOfYear = Table.AddColumn(AddMonthName, "WeekOfYear", each Date.WeekOfYear([Date]), Int64.Type),
    AddWeekString = Table.AddColumn(AddWeekOfYear, "Week_Num", each "Week-" & Text.From([WeekOfYear]), type text),
    AddDayOfWeek = Table.AddColumn(AddWeekString, "DayOfWeek", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
    AddDayName = Table.AddColumn(AddDayOfWeek, "DayName", each Date.ToText([Date], "dddd"), type text)
in
    AddDayName
```

---

## 🛡️ Data Quality Validation Steps in Power Query

1. **Verify No Schema Drifts**:
   The `MissingField.Ignore` argument in `Table.RenameColumns` ensures that if future files already use `Total_Trans_Vol`, the script does not break.
2. **Handle Null Values**:
   Any missing values in numeric fields are replaced with `0` or filtered out using `Table.SelectRows`.
3. **Verify Distinct Primary Keys**:
   Right-click `Client_Num` in `customer` query and select **Remove Duplicates** to guarantee relational 1-to-many cardinality.

---

## ⚡ 6. Enterprise Incremental Refresh Configuration (Power BI Service)

For large-scale enterprise deployments hosting millions of credit card transactions, loading the full historical table on every refresh cycle creates unnecessary network load and gateway bottlenecks. Power BI Service provides native **Incremental Refresh Policies** governed by two reserved `DateTime` parameters:

### Step 6.1: Define Range Parameters in Power Query
Create two parameters with type `Date/Time`:
```powerquery
// RangeStart Parameter
RangeStart = #datetime(2023, 1, 1, 0, 0, 0) meta [IsParameterQuery=true, Type="DateTime", IsParameterQueryRequired=true]

// RangeEnd Parameter
RangeEnd = #datetime(2023, 12, 31, 23, 59, 59) meta [IsParameterQuery=true, Type="DateTime", IsParameterQueryRequired=true]
```

### Step 6.2: Apply Incremental Filter Step to Fact Table
Add a datetime filter to the `credit_card` query before loading into VertiPaq:
```powerquery
// Apply Range Filtering to enable Query Folding and Partition Pruning
Filtered_Date_Range = Table.SelectRows(
    Parsed_Dates,
    each DateTime.From([Week_Start_Date]) >= RangeStart and DateTime.From([Week_Start_Date]) < RangeEnd
)
```

### Step 6.3: Power BI Desktop Incremental Policy Settings
Right-click `credit_card` in the Fields pane and select **Incremental refresh**:
- **Store rows where column `Week_Start_Date` is in the last**: `3 Years` (Archive partition).
- **Refresh rows where column `Week_Start_Date` is in the last**: `2 Weeks` (Active partition for Week 52 / Week 53 updates).
- **Detect data changes**: Check `current_year` or `Week_Num_Int` to avoid refreshing unchanged historical weeks.

---

## 🔍 7. Power Query Query Folding Analysis & Optimization Matrix

Query Folding enables Power Query to push data transformations back to the source relational database (PostgreSQL/SQL Server), executing operations on server hardware before data transmission:

| ETL Operation | Folding Status | Native SQL Translation | Optimization Recommendation |
| :--- | :--- | :--- | :--- |
| `Table.SelectRows` (Filtering) | 🟢 **Folds** | `WHERE Week_Start_Date >= ...` | Place filters as early as possible in the query pipeline. |
| `Table.RemoveColumns` / Select Columns | 🟢 **Folds** | `SELECT Client_Num, Total_Trans_Amt...` | Eliminate unnecessary columns before applying merges. |
| `Table.Join` / Merge Queries | 🟢 **Folds** | `INNER JOIN / LEFT JOIN ... ON ...` | Ensure joined keys share identical types (`BIGINT`). |
| `Table.RenameColumns` | 🟢 **Folds** | `SELECT col AS new_col` | Rename columns directly in SQL or early in M. |
| `Date.FromText` (Custom Culture) | 🔴 **Breaks** | Requires .NET in-memory parsing | Use native SQL `TO_DATE(Week_Start_Date, 'DD-MM-YYYY')` in staging. |
| `Text.Trim` / String Cleansing | 🟡 **Partial** | `TRIM(col)` in PostgreSQL | Ensure database collation matches Power BI settings. |
| `Table.Combine` (CSV Append) | 🔴 **Breaks** | File-based operation | Migrate batch append to a PostgreSQL `UNION ALL` View. |


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
| 🛡️ **Credit Risk Policy** | Basel III Expected Loss, underwriting & sentries | [`docs/RISK_AND_CREDIT_POLICY_ANALYSIS.md`](RISK_AND_CREDIT_POLICY_ANALYSIS.md) |
| 🚀 **Marketing Playbook** | 14-day activation funnels & digital channel shift | [`docs/MARKETING_AND_PORTFOLIO_OPTIMIZATION.md`](MARKETING_AND_PORTFOLIO_OPTIMIZATION.md) |
| 🎙️ **Interview & Case Study** | STAR project defense & 15+ technical interview Q&A | [`docs/INTERVIEW_QA_AND_PORTFOLIO_CASE_STUDY.md`](INTERVIEW_QA_AND_PORTFOLIO_CASE_STUDY.md) |
| 🧪 **Data Validation Report**| Official 31-point mathematical reconciliation report | [`docs/DATA_VALIDATION_REPORT.md`](DATA_VALIDATION_REPORT.md) |
| 🛠️ **SQL Pipeline** | Production PostgreSQL DDL, staging tables & views | [`docs/SQL_SCRIPTS.sql`](SQL_SCRIPTS.sql) |
| 📖 **Master README** | Master repository overview & setup instructions | [`README.md`](../README.md) |
