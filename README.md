Welcome to the **ShopSphere Data Warehouse and Analysis Project** repository! 🚀

This project demonstrates a **comprehensive end-to-end data warehousing and analytics solution**
for a global e-commerce retailer operating across two independent sales channels — a legacy
website platform and a modern mobile application.

Designed as a **hands-on portfolio project**, it highlights industry best practices in
**data engineering and analytics**, including Medallion Architecture design, multi-source
data integration, data quality management, and SQL-based analytical reporting.

---

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective
Develop a modern data warehouse using **SQL Server** to consolidate e-commerce transaction
data from two channels, enabling unified analytical reporting and informed decision-making.

#### Specifications
- **Data Sources**: Import data from two source systems (**Website Platform** and **Mobile
  Application**) provided as CSV files
- **Data Quality**: Cleanse and resolve data quality issues prior to analysis including
  mixed date formats, inconsistent status codes, currency encoding corruption, duplicate
  records, and null values
- **Integration**: Combine both sources into a single unified data model designed for
  analytical queries using a star schema
- **Scope**: Full historical dataset covering January 2023 — December 2024
- **Documentation**: Provide clear documentation of the data model to support both business
  stakeholders and analytics teams

---

## 📊 BI: Analytics & Reporting (Data Analytics)

### Objective
Develop SQL-based analytics to deliver detailed insights into:

- **Customer Behaviour** — RFM segmentation across 22,000+ unique customers
- **Product Performance** — Revenue and volume analysis across 80 products and 6 categories
- **Sales Trends** — Monthly revenue trends across two years and two channels
- **Promotional Effectiveness** — Promo code performance analysis across 12 distinct codes
- **Strategic Ad Spend** — Data-backed $500,000 advertising budget recommendation

These insights empower stakeholders with key business metrics, enabling data-driven and
strategic decision-making.

---

## 🏗️ Medallion Architecture

The pipeline is built on a three-layer **Medallion Architecture**:
```
Bronze (Raw Ingestion)
    └── Silver (Cleaning & Standardisation)
            └── Gold (Star Schema & Analytics)
```

| Layer | Purpose | Load Type |
|-------|---------|-----------|
| Bronze | Raw ingestion — no transformations, all columns NVARCHAR | TRUNCATE + BULK INSERT |
| Silver | Cleaning, deduplication, type casting, standardisation | TRUNCATE + CTE INSERT |
| Gold | Star schema — surrogate keys, USD conversion, analytical flags | FULL REBUILD |

---

## 🗄️ Data Warehouse Design

The Gold layer is designed using a **dimensional star schema** optimised for analytical workloads.

### Fact Table
- **fact_orders**
  - Total Amount (source currency)
  - Total Amount USD (converted)
  - Total Amount Recalculated USD (from components)
  - Quantity
  - Unit Price
  - Discount
  - Shipping Cost
  - Order Status
  - Channel (Website / Mobile App)
  - Data Quality Flags

### Dimension Tables

| Table | Description |
|-------|-------------|
| `dim_date` | Full calendar spine — date_key in YYYYMMDD INT format |
| `dim_customer` | Unified customers from both channels — cross-channel flag included |
| `dim_product` | 80 unified products across both channels |
| `dim_geography` | Country-level — US, UK, Germany, France |
| `dim_payment` | Payment methods categorised as Card or Digital Wallet |
| `dim_promo` | 12 promo codes typed by Seasonal, Flash, Welcome, VIP, Other |
| `dim_device` | iOS / Android / N/A for website orders |

This design ensures high query performance and intuitive reporting across both channels.

---

## 🧪 Data Quality & Transformation

The following data processing steps are applied in the Silver layer:

| Issue | Treatment |
|-------|-----------|
| Duplicate records | Removed using ROW_NUMBER() after normalisation |
| Mixed date/timestamp formats | Pattern-matched CASE statements → TRY_CAST to DATE/DATETIME |
| Null customer names | Replaced with `'Unknown'` |
| Null shipping addresses | Replaced with `'Not Provided'` |
| Null user emails | Replaced with `'Guest'` |
| Inconsistent status codes | Mapped to canonical values (Completed, Shipped, Pending, Cancelled, Delivered, Returned) |
| Currency encoding corruption | ASCII byte-level matching → ISO codes (USD/GBP/EUR) |
| Inconsistent product ID formats | All variants normalised to `PROD-NNN` |
| Category aliases (23 variants) | Mapped to 6 canonical categories |
| Negative unit prices | Flagged with `is_negative_price` — excluded from revenue |
| Total amount mismatches | Flagged with `is_total_mismatch` — recalculated total added in Gold |

---

## 📈 Analytical Deliverables

### 1. 📋 Overview KPIs
20 executive-level metrics across 6 categories — Revenue, Volume, Customer, Product,
Geography, and Operational Health.

### 2. 👥 RFM Customer Segmentation
Scores every registered customer on Recency, Frequency, and Monetary value using NTILE(5).
Assigns 9 segment labels from Champion to Lost with full channel breakdown.

### 3. 🛒 Market Basket Analysis
Identifies product pairs most frequently purchased together using self-join on website orders.
Calculates support, confidence (A→B and B→A), and lift for all product combinations.

### 4. 🎟️ Promo Code Effectiveness
Compares promo vs non-promo orders across AOV, revenue contribution, redemption rate,
estimated discount value, and customer tier targeting.

### 5. 💰 $500K Ad Spend Recommendation
Data-backed budget allocation across channel, geography, device, and product category.
Revenue-proportional allocations calculated directly from the fact table.

---

## 🛠️ Tools & Technologies

| Category | Technology |
|----------|------------|
| Database | Microsoft SQL Server 2019 |
| Language | T-SQL |
| Architecture | Medallion (Bronze / Silver / Gold) |
| Data Modeling | Star Schema (Kimball) |
| Source Data | CSV Files (2 sources, 76,685 rows) |
| Ingestion | BULK INSERT |
| Transformation | CTEs, Window Functions, TRY_CAST |
| Analytics | SQL Queries — RFM, Basket Analysis, KPIs |
| Version Control | Git & GitHub |

---

## 📁 Repository Structure
```text
ShopSphere Data Warehouse and Analysis Project/
│
├── datasets/
│   ├── website_orders.csv
│   └── mobile_app_transactions.csv
│
├── scripts/
│   ├── 00_init_database.sql
│   ├── 01_bronze_ddl_load.sql
│   ├── 02_silver_website_orders.sql
│   ├── 03_silver_mobile_app.sql
│   ├── 04_gold_ddl_load.sql
│   ├── 05_overview_kpis.sql
│   ├── 06_rfm_segmentation.sql
│   ├── 07_market_basket.sql
│   ├── 08_promo_effectiveness.sql
│   ├── 09_ad_spend_recommendation.sql
│   └── 10_run_full_pipeline.sql
│
├── docs/
│   ├── architecture_diagram.png
│   └── data_dictionary.md
│
└── README.md
```

---

## 🔄 Pipeline Orchestration

All load procedures are wrapped in a single master orchestrator:
```sql
EXEC dbo.run_full_pipeline;
```

**Execution order:**
1. `bronze.load_bronze`
2. `silver.load_silver_website_orders`
3. `silver.load_silver_mobile_app_transactions`
4. `gold.load_gold`

Full error handling and batch timing logged at each stage.

---

## ▶️ How to Run

**Prerequisites:**
- Microsoft SQL Server 2019 or later
- SSMS or Azure Data Studio
- CSV dataset files

**Steps:**
1. Run `00_init_database.sql` — creates `ShopSphereDB` and all three schemas
2. Update file paths in `01_bronze_ddl_load.sql` to match your local CSV locations
3. Run scripts in order: `01` → `02` → `03` → `04`
4. **OR** run `10_run_full_pipeline.sql` to execute all load procedures in one shot
5. Run `05` through `09` for all analytical outputs

---

## 📖 Data Quality Notes

> **Known Limitation — Mobile App Total Mismatch:**
> The `is_total_mismatch` flag fires on 100% of mobile app transactions. This is expected
> behaviour. The app's `gross_total` reflects a promo discount baked into the final amount
> that is not stored as a separate column. The variance between `total_amount_usd` and
> `total_amount_recalc_usd` on app rows represents the estimated promo discount value.
> This is documented as a source system limitation, not a pipeline error.

---

## 📜 License
This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

*Built by **Nte Daniel Daniel** | Cohort 7 | Data Engineering Programme | 2025*
*Next iteration: Incremental load pattern + performance optimisation with indexing strategy*
