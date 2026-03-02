# ShopSphere — Analytical Insights & Recommendations

## Executive Summary

ShopSphere generated **$9.48M in total revenue** across **60,331 orders** and **75,675 order lines** between January 2023 and December 2024. The business operates across two channels — a website platform and a mobile application — serving customers across four markets: United States, United Kingdom, Germany, and France.

The analysis covers four strategic areas: customer segmentation, product association, promotional effectiveness, and advertising allocation.

---

## 1. Revenue & Channel Performance

The website is the dominant revenue channel, contributing **$6.4M (67.6%)** of total revenue against the app's **$3.07M (32.4%)**. Website AOV of **$131.59** consistently outpaces the app's **$113.86**, a gap that holds across every month in the dataset.

Monthly trends reveal two clear seasonal peaks in both years — **November and December** — with November 2023 ($545K) and December 2024 ($614K) representing the highest monthly revenue figures. This pattern is consistent across both channels and all markets, confirming a strong Q4 concentration.

**Recommendation:** Q4 campaign planning should begin no later than September. Budget reallocation toward Q4 activations — particularly for high-AOV categories — will yield the highest return on ad spend given the demonstrated demand concentration.

---

## 2. Geographic Performance

The United States dominates with **$6.39M (67.4%)** of total revenue. The United Kingdom is a meaningful second at **$1.91M (20.2%)**, followed by Germany at **$764K (8.1%)** and France at **$414K (4.4%)**.

Notably the UK website AOV of **$170.61** is the highest of any country-channel combination in the dataset — significantly above the US website AOV of $127.26. This signals that UK customers are either purchasing higher-value products or purchasing in larger quantities per order.

**Recommendation:** The UK market is underinvested relative to its value signal. A customer who converts in the UK spends more per order than any other market. Targeted acquisition spend in the UK, particularly on the website channel, is likely to yield above-average returns.

---

## 3. Customer Segmentation — RFM Analysis

**22,155 registered customers** were segmented across nine RFM tiers.

### Revenue Concentration
The top two segments — **Champions** (2,261 customers) and **Loyals** (3,744 customers) — together contribute **$4.2M**, representing **44.6% of total revenue** from just **27% of customers**. Champions average **5.3 orders** and **$922 per customer**. Loyals average **3.9 orders** and **$565 per customer**.

### At-Risk Revenue
**At Risk** customers (3,694) haven't ordered in an average of **328 days** but have historically spent **$376 each**, representing **$1.39M** in deteriorating relationships. **Lost** customers (2,443) average **564 days** since last order with only **$89 average spend** — recovery is unlikely and largely not worth the investment.

### Growth Opportunity
**Potential Loyalists** (2,577 customers, $1.6M revenue) and **New Customers** (2,857 customers, $657K revenue) represent the primary conversion opportunity. New Customers average only **1.5 orders** — the pipeline exists, the repeat purchase behaviour has not yet been established.

### Cross-Channel Insight
Customers active on **both channels** are overwhelmingly concentrated in the Champion and Loyal segments — 1,847 Champions and 2,619 Loyals are cross-channel customers. Single-channel customers dominate the Lost, At Risk, and New Customer segments.

**Recommendations:**
- Protect Champions and Loyals with exclusive access, early product launches, and loyalty rewards. Do not discount this segment — their spend is already high and promos erode margin without driving incremental volume here.
- Activate At Risk customers with a targeted re-engagement campaign before they cross into Lost. At 328 days average recency, many are still recoverable. A single well-timed touchpoint — personalised to their purchase history — is the right intervention.
- Invest in converting New Customers to repeat buyers within the first 60 days. The data shows that customers who place a second order tend to progress toward Loyal behaviour. A structured post-purchase sequence (email, app push, personalised offer) targeting the 2,857 New Customers should be a Q1 priority.
- Cross-channel acquisition is the highest-value growth lever. Cross-channel customers generate **$607.69 revenue per customer** versus **$339.43 for website-only** and **$177.75 for app-only**. Any strategy that moves a single-channel customer to both channels has a demonstrable 2–3x revenue uplift.

---

## 4. Market Basket Analysis

Website orders average **1.46 items per basket** at an average basket value of **$192.16**. Given 80 products across 6 categories, the basket size indicates most customers are purchasing across categories rather than stacking within a single category.

### Strongest Product Associations (by Lift)

| Product A | Product B | Lift |
|-----------|-----------|------|
| Soccer Ball Professional | Bike Lock Heavy Duty | 1.69 |
| Women's Yoga Pants | Python Programming for Beginners | 1.54 |
| Storage Bins Set | Basketball Official Size | 1.48 |
| Air Fryer 5-Quart | Table Lamp Modern | 1.47 |
| Jump Rope Speed | Bike Lock Heavy Duty | 1.47 |

Lift values above 1.5 are meaningful in a dataset of this size. The Soccer Ball + Bike Lock pairing at 1.69 is the strongest association in the catalogue.

### Strongest Category Associations (by Support)

| Category A | Category B | Support |
|------------|------------|---------|
| Electronics | Fashion | 4.21% |
| Fashion | Sports | 4.02% |
| Fashion | Home & Kitchen | 3.64% |
| Electronics | Sports | 3.63% |
| Home & Kitchen | Sports | 3.37% |

Electronics + Fashion is the most common cross-category pairing, appearing together in 4.21% of all website orders.

**Recommendations:**
- Implement product recommendation engines on the website surfacing the top lift pairs at cart and checkout. The Soccer Ball + Bike Lock association (1.69 lift) and the Yoga Pants + Programming Book pairing (1.54 lift) are non-obvious cross-category signals that a human merchandiser would not intuit — this is exactly where data-driven recommendations add value.
- Bundle promotions for Electronics + Fashion and Fashion + Sports pairings. These are the highest-support category combinations. A "Sport + Style" bundle or a "Tech + Lifestyle" campaign targeting website customers has a data-backed audience.
- The average basket is 1.46 items. Increasing this to 1.6 through recommendation-driven cross-sells would add approximately $28 per order — at 33,331 website orders that represents **~$930K in incremental annual revenue** without acquiring a single new customer.

---

## 5. Promotional Effectiveness

Promo codes were applied to **19.05%** of mobile app orders, generating **$592,890** in revenue. The critical finding is that **promos are not driving meaningful AOV uplift**.

| | Orders | AOV | Revenue |
|---|---|---|---|
| No Promo | 21,856 (80.95%) | $113.53 | $2,481,394 |
| Promo Applied | 5,144 (19.05%) | $115.26 | $592,890 |

The AOV difference between promo and non-promo orders is **$1.73** — functionally insignificant. Customers are not adding more to their basket because of a promo code. They are using the code on a purchase they were already going to make.

### By Promo Type
| Promo Type | Redemptions | AOV | Estimated Discount Given |
|------------|-------------|-----|--------------------------|
| Other | 2,088 | $117.05 | $15,699 |
| Seasonal | 765 | $118.28 | $5,726 |
| Welcome | 729 | $120.20 | $5,337 |
| VIP | 815 | $104.91 | $6,255 |
| Flash | 747 | $113.62 | $5,710 |

VIP30 has the highest redemption count (815) but the **lowest AOV** ($104.91) — a 30% discount is attracting the most price-sensitive customers and delivering the least per-order value. Welcome15 has the highest AOV ($120.20) and the lowest discount cost ($5,337), making it the most efficient code in the portfolio.

### By Customer Tier
High value customers (top 20%) generate **$170.34 AOV with a promo** versus **$164.23 without**. The lift is marginal. High value customers are spending at a high level regardless — the promo is not the driver.

**Recommendations:**
- **Restructure VIP30.** A 30% blanket discount applied to 815 transactions that delivers only $104.91 AOV is the worst-performing code by value efficiency. Replace with a tiered reward (e.g. bonus product, free shipping, early access) that drives engagement without eroding margin.
- **Scale Welcome15.** At $120.20 AOV and only $5,337 in total discount given, it is the most efficient acquisition code. Increase its reach in onboarding flows.
- **Stop discounting Champions and Loyals.** The promo by customer tier data shows high-value customers spend nearly the same regardless of promo. Every discount applied to this segment is pure margin erosion. Reserve promos for At Risk re-engagement and New Customer conversion — segments where the incentive may actually change behaviour.
- **Test promo removal on high-AOV categories.** Home & Kitchen promo orders average $149–167 AOV depending on type. These customers are buying high-value items and would likely convert without a discount. Run an A/B test removing promos from Home & Kitchen and measuring conversion rate impact before assuming the promo is necessary.

---

## 6. $500K Ad Spend Recommendation

All allocations are revenue-proportional, derived directly from two years of transaction data.

### By Channel

| Channel | Revenue Share | Recommended Budget |
|---------|--------------|-------------------|
| Website | 67.57% | **$337,842** |
| Mobile App | 32.43% | **$162,158** |

The website drives 2x the revenue and 16% higher AOV. It earns the majority of budget. However the app's 32% allocation is not just proportional — it is strategic. Cross-channel customers (who skew heavily app-active) generate 3.4x the revenue of app-only customers. App investment is partially a website revenue investment.

### By Geography

| Market | Revenue Share | Recommended Budget |
|--------|--------------|-------------------|
| United States | 67.39% | **$336,943** |
| United Kingdom | 20.17% | **$100,864** |
| Germany | 8.07% | **$40,331** |
| France | 4.37% | **$21,863** |

The US receives the largest allocation by volume. The UK allocation of $100,864 should be weighted toward website acquisition given the UK's $170.61 website AOV — the highest in the dataset.

### By Device (Mobile App Budget)

| Device | Revenue Share | Recommended Budget |
|--------|--------------|-------------------|
| iOS | 57.55% | **$287,728** |
| Android | 42.45% | **$212,272** |

iOS drives 57.6% of app revenue. Apple App Store and iOS-targeted ad placements should receive the majority of mobile investment.

### By Category

| Category | Revenue Share | Recommended Budget |
|----------|--------------|-------------------|
| Home & Kitchen | 21.96% | **$109,810** |
| Fashion | 21.72% | **$108,579** |
| Sports | 20.13% | **$100,657** |
| Electronics | 19.17% | **$95,859** |
| Beauty | 10.51% | **$52,556** |
| Books | 6.51% | **$32,539** |

The top four categories are tightly distributed within a 2.8% revenue share band — no single category dominates. This healthy distribution means category-level budget cuts carry real revenue risk. **Home & Kitchen at $160.67 AOV** is the highest-value category per order and merits the top allocation. Books at $72.81 AOV is the lowest — its budget should be monitored for efficiency.

### Strategic Overlay

The data points to three high-conviction actions within the $500K:

**1. UK Website Acquisition — over-index here.** $100K to the UK market should be disproportionately weighted toward website channels given the $170.61 AOV signal. UK website customers are the highest-value customer profile in the dataset.

**2. iOS Cross-Channel Retargeting.** The highest-value customers are cross-channel. iOS users represent 57.5% of app revenue. A retargeting campaign converting iOS-only app customers to also engage the website — or vice versa — targets the segment with the clearest revenue uplift potential.

**3. Q4 Concentration.** November and December account for a disproportionate share of annual revenue in both 2023 and 2024. Frontloading budget into Q3 brand-building (July–September) to prime demand ahead of Q4 activation is the most efficient use of the annual budget cycle.

---

*Analysis based on 76,685 order lines | January 2023 — December 2024 | ShopSphere E-Commerce*
*All revenue figures in USD using fixed conversion rates: GBP × 1.27, EUR × 1.08*
