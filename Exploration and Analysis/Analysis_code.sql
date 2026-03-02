/********************************************************************************************
 SCRIPT NAME : GOLD LAYER — OVERVIEW AND ANALYSIS
 DESCRIPTION :
     EXECUTIVE DASHBOARD — KPIs and Deliverables
     ALL FIGURES IN USD. EXCLUDES NEGATIVE PRICE ROWS FROM REVENUE.
********************************************************************************************/

------------------------------------------------------------
-- CATEGORY 1: REVENUE KPIs
------------------------------------------------------------

-- 1.1 Total Revenue USD

SELECT 
    ROUND(SUM(total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(total_amount_recalc_usd), 2)       AS AOV,
    COUNT(*)                                     AS total_Order_lines
FROM
    gold.fact_orders
WHERE
    is_negative_price = 0;


-- 1.2 Revenue and AOV by Channel

SELECT 
    channel,
    ROUND(SUM(total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(total_amount_recalc_usd), 2)       AS AOV,
    COUNT(*)                                     AS total_Order_lines
FROM
    gold.fact_orders
WHERE
    is_negative_price = 0
GROUP BY
    Channel
   ORDER BY total_revenue DESC;


-- 1.3 Monthly Revenue Trend (both channels combined)


SELECT 
    d.year_number,
    d.month_number,
    d.month_name,
    d.quarter_name,
    ROUND(SUM(f.total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)       AS AOV,
    COUNT(*)                                       AS total_Order_lines
FROM
    gold.fact_orders f
INNER JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE
    is_negative_price = 0
GROUP BY
    d.year_number,
    d.month_number,
    d.month_name,
    d.quarter_name
   ORDER BY 
     d.year_number,
    d.month_number;


-- 1.4 Monthly Revenue Trend by Channel


SELECT 
    d.year_number,
    d.month_number,
    d.month_name,
    d.quarter_name,
    f.channel,
    ROUND(SUM(f.total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)       AS AOV,
    COUNT(*)                                       AS total_Order_lines
FROM
    gold.fact_orders f
INNER JOIN gold.dim_date d ON f.date_key = d.date_key
WHERE
    is_negative_price = 0
GROUP BY
    d.year_number,
    d.month_number,
    d.month_name,
    d.quarter_name,
    f.channel
   ORDER BY 
    d.year_number,
    d.month_number,
    f.channel;

------------------------------------------------------------
-- CATEGORY 2: VOLUME KPIs
------------------------------------------------------------

-- 2.1 Total Orders and Units Sold
SELECT
    COUNT(*)                               AS total_order_lines,
    COUNT(DISTINCT order_id)               AS total_distinct_orders,
    SUM(quantity)                          AS total_units_sold
FROM gold.fact_orders
WHERE is_negative_price = 0;


-- 2.2 Orders by Channel
SELECT
    channel,
    COUNT(DISTINCT order_id)               AS total_orders,
    SUM(quantity)                          AS total_units_sold
FROM gold.fact_orders
WHERE is_negative_price = 0
GROUP BY channel
ORDER BY total_orders DESC;


-- 2.3 Orders by Status
SELECT
    order_status,
    COUNT(*)                               AS order_count,
    ROUND(COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(), 2)         AS pct_of_total
FROM gold.fact_orders
WHERE is_negative_price = 0
GROUP BY order_status
ORDER BY order_count DESC;

------------------------------------------------------------
-- CATEGORY 3: CUSTOMER KPIs
------------------------------------------------------------

-- 3.1 Total Unique Customers
SELECT
    COUNT(*)                               AS total_customers,
    SUM(CASE WHEN is_guest = 1 THEN 1 ELSE 0 END) AS guest_customers,
    SUM(CASE WHEN is_guest = 0 THEN 1 ELSE 0 END) AS registered_customers
FROM gold.dim_customer;

-- 3.2 Channel Overlap Breakdown
SELECT
    preferred_channel,
    COUNT(*)                               AS customer_count,
    ROUND(COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(), 2)         AS pct_of_total
FROM gold.dim_customer
WHERE is_guest = 0
GROUP BY preferred_channel
ORDER BY customer_count DESC;


-- 3.3 Average Orders Per Customer
SELECT
    f.channel,
    COUNT(DISTINCT f.order_id)             AS total_orders,
    COUNT(DISTINCT f.customer_key)         AS total_customers,
    ROUND(
        CAST(COUNT(DISTINCT f.order_id) AS FLOAT)
        / NULLIF(COUNT(DISTINCT f.customer_key), 0)
    , 2)                                   AS avg_orders_per_customer
FROM gold.fact_orders f
WHERE f.is_negative_price = 0
  AND f.customer_key IS NOT NULL
GROUP BY f.channel
ORDER BY avg_orders_per_customer DESC;


------------------------------------------------------------
-- CATEGORY 4: PRODUCT KPIs
------------------------------------------------------------

-- 4.1 Top 10 Products by Revenue

SELECT TOP 10
    p.product_id,
    p.product_name,
    p.category,
    COUNT(*)                                       AS Order_lines,
    SUM(f.quantity)                                AS units_sold,
    ROUND(SUM(f.total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)       AS AOV   
FROM
    gold.fact_orders f
INNER JOIN gold.dim_product p ON f.product_key = p.product_key
WHERE
    f.is_negative_price = 0
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC


-- 4.2 Top 10 Products by Volume
SELECT TOP 10
    p.product_id,
    p.product_name,
    p.category,
    SUM(f.quantity)                               AS units_sold,
    ROUND(SUM(f.total_amount_recalc_usd), 2)      AS total_revenue_usd
FROM gold.fact_orders f
JOIN gold.dim_product p ON f.product_key = p.product_key
WHERE f.is_negative_price = 0
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold DESC;

-- 4.3 Revenue by Category
SELECT 
    p.category,
    COUNT(*)                                       AS Order_lines,
    SUM(f.quantity)                                AS units_sold,
    ROUND(SUM(f.total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)       AS AOV   
FROM
    gold.fact_orders f
INNER JOIN gold.dim_product p ON f.product_key = p.product_key
WHERE
    f.is_negative_price = 0
GROUP BY p.category
ORDER BY total_revenue DESC;


------------------------------------------------------------
-- CATEGORY 5: GEOGRAPHY KPIs
------------------------------------------------------------

-- 5.1 Revenue by Country

SELECT 
    g.country,
    f.channel,
    COUNT(*)                                       AS Order_lines,
    SUM(f.quantity)                                AS units_sold,
    ROUND(SUM(f.total_amount_recalc_usd), 2)       AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)       AS AOV,
    ROUND(SUM(f.total_amount_recalc_usd) * 100
        / SUM(SUM(f.total_amount_recalc_usd)) OVER(), 2)  AS pct_of_rev
FROM
    gold.fact_orders f
INNER JOIN gold.dim_geography g ON f.geography_key = g.geography_key
WHERE
    f.is_negative_price = 0
    AND g.country != 'N/A'
GROUP BY g.country, f.channel
ORDER BY total_revenue DESC;

------------------------------------------------------------
-- CATEGORY 6: OPERATIONAL HEALTH KPIs
------------------------------------------------------------

-- 6.1 Return Rate and Cancellation Rate
SELECT
    COUNT(*)                            AS total_orders,
    SUM(CASE WHEN order_status = 'Returned'
        THEN 1 ELSE 0 END)              AS Returned_orders,
    ROUND(SUM(CASE WHEN order_status = 'Returned'
        THEN 1 ELSE 0 END) * 100
            / COUNT(*),2)               AS return_rate_pct,

    SUM(CASE WHEN order_status = 'Cancelled'
        THEN 1 ELSE 0 END)              AS Cancelled_orders,
    ROUND(SUM(CASE WHEN order_status = 'Cancelled'
        THEN 1 ELSE 0 END) * 100
            / COUNT(*),2)               AS Cancel_rate_pct
FROM
    gold.fact_orders

-- 6.2 Return and Cancellation Rate by Channel
SELECT
    channel,
    COUNT(*)                                AS total_orders,
    ROUND(SUM(CASE WHEN order_status = 'Returned'
        THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                      AS return_rate_pct,
    ROUND(SUM(CASE WHEN order_status = 'Cancelled'
        THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                      AS cancellation_rate_pct
FROM gold.fact_orders
GROUP BY channel
ORDER BY channel;


/********************************************************************************************
 RFM VIEW — REUSABLE BASE FOR ALL THREE RFM QUERIES
********************************************************************************************/

CREATE OR ALTER VIEW gold.vw_rfm_segments AS

WITH rfm_base AS (
    SELECT
        f.customer_key,
        c.customer_email,
        c.preferred_channel,
        MAX(d.full_date)                                AS last_order_date,
        DATEDIFF(DAY, MAX(d.full_date),
            (SELECT MAX(full_date) FROM gold.dim_date)) AS recency_days,
        COUNT(DISTINCT f.order_id)                      AS frequency,
        ROUND(SUM(f.total_amount_recalc_usd), 2)        AS monetary
    FROM gold.fact_orders f
    JOIN gold.dim_customer c ON f.customer_key = c.customer_key
    JOIN gold.dim_date d     ON f.date_key     = d.date_key
    WHERE f.is_negative_price = 0
      AND c.is_guest          = 0
    GROUP BY f.customer_key, c.customer_email, c.preferred_channel
),
rfm_scores AS (
    SELECT
        customer_key,
        customer_email,
        preferred_channel,
        last_order_date,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
)
SELECT
    customer_key,
    customer_email,
    preferred_channel,
    last_order_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CAST(r_score AS NVARCHAR)
        + CAST(f_score AS NVARCHAR)
        + CAST(m_score AS NVARCHAR)                 AS rfm_score,
    CASE
        WHEN r_score = 5 AND f_score >= 4 AND m_score >= 4
            THEN 'Champion'
        WHEN r_score >= 4 AND f_score >= 3
            THEN 'Loyal'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
            THEN 'Potential Loyalist'
        WHEN r_score >= 4 AND f_score <= 2
            THEN 'New Customer'
        WHEN r_score = 3 AND f_score <= 3
            THEN 'Needs Attention'
        WHEN r_score = 2 AND f_score >= 2
            THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3
            THEN 'Cannot Lose Them'
        WHEN r_score = 1 AND f_score = 1
            THEN 'Lost'
        ELSE 'Hibernating'
    END                                             AS segment
FROM rfm_scores;
GO


/********************************************************************************************
 DELIVERABLE 1 — RFM CUSTOMER SEGMENTATION
********************************************************************************************/

-- Step 4: Full customer-level RFM output
SELECT
    customer_key,
    customer_email,
    preferred_channel,
    last_order_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    segment
FROM gold.vw_rfm_segments
ORDER BY monetary DESC;


-- Step 5: Segment summary
SELECT
    segment,
    COUNT(*)                                        AS customer_count,
    ROUND(COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(), 2)                  AS pct_of_customers,
    ROUND(AVG(recency_days), 0)                     AS avg_recency_days,
    ROUND(AVG(CAST(frequency AS FLOAT)), 1)         AS avg_frequency,
    ROUND(AVG(monetary), 2)                         AS avg_monetary,
    ROUND(SUM(monetary), 2)                         AS total_revenue
FROM gold.vw_rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;


-- Step 6: Segment breakdown by preferred channel
SELECT
    preferred_channel,
    segment,
    COUNT(*)                                        AS customer_count
FROM gold.vw_rfm_segments
GROUP BY preferred_channel, segment
ORDER BY preferred_channel, customer_count DESC;


/********************************************************************************************
 DELIVERABLE 2 — MARKET BASKET ANALYSIS
********************************************************************************************/

-- Step 1-2: Product pairs with support, confidence, lift
WITH website_baskets AS (
    SELECT
        f.order_id,
        p.product_id,
        p.product_name,
        p.category
    FROM gold.fact_orders f
    JOIN gold.dim_product p ON f.product_key = p.product_key
    WHERE f.channel           = 'Website'
      AND f.is_negative_price = 0
),
product_pairs AS (
    SELECT
        a.order_id,
        a.product_id    AS product_a_id,
        a.product_name  AS product_a_name,
        a.category      AS category_a,
        b.product_id    AS product_b_id,
        b.product_name  AS product_b_name,
        b.category      AS category_b
    FROM website_baskets a
    JOIN website_baskets b
        ON  a.order_id   = b.order_id
        AND a.product_id < b.product_id
),
pair_counts AS (
    SELECT
        product_a_id,
        product_a_name,
        category_a,
        product_b_id,
        product_b_name,
        category_b,
        COUNT(DISTINCT order_id)                    AS pair_frequency
    FROM product_pairs
    GROUP BY
        product_a_id, product_a_name, category_a,
        product_b_id, product_b_name, category_b
),
total_orders AS (
    SELECT COUNT(DISTINCT order_id) AS n
    FROM gold.fact_orders
    WHERE channel           = 'Website'
      AND is_negative_price = 0
),
product_freq AS (
    SELECT
        p.product_id,
        COUNT(DISTINCT f.order_id)                  AS product_frequency
    FROM gold.fact_orders f
    JOIN gold.dim_product p ON f.product_key = p.product_key
    WHERE f.channel           = 'Website'
      AND f.is_negative_price = 0
    GROUP BY p.product_id
)
SELECT TOP 50
    pc.product_a_id,
    pc.product_a_name,
    pc.category_a,
    pc.product_b_id,
    pc.product_b_name,
    pc.category_b,
    pc.pair_frequency,
    ROUND(pc.pair_frequency * 100.0
        / t.n, 4)                                   AS support_pct,
    ROUND(pc.pair_frequency * 100.0
        / pfa.product_frequency, 2)                 AS confidence_a_to_b_pct,
    ROUND(pc.pair_frequency * 100.0
        / pfb.product_frequency, 2)                 AS confidence_b_to_a_pct,
    ROUND(
        (pc.pair_frequency * 1.0 / t.n)
        /
        (
            (pfa.product_frequency * 1.0 / t.n)
            * (pfb.product_frequency * 1.0 / t.n)
        )
    , 4)                                            AS lift
FROM pair_counts pc
CROSS JOIN total_orders t
JOIN product_freq pfa ON pc.product_a_id = pfa.product_id
JOIN product_freq pfb ON pc.product_b_id = pfb.product_id
ORDER BY lift DESC;


-- Step 3: Cross-category pair analysis
WITH website_baskets AS (
    SELECT
        f.order_id,
        p.category
    FROM gold.fact_orders f
    JOIN gold.dim_product p ON f.product_key = p.product_key
    WHERE f.channel           = 'Website'
      AND f.is_negative_price = 0
),
category_pairs AS (
    SELECT
        a.order_id,
        a.category AS category_a,
        b.category AS category_b
    FROM website_baskets a
    JOIN website_baskets b
        ON  a.order_id  = b.order_id
        AND a.category  < b.category
)
SELECT
    category_a,
    category_b,
    COUNT(DISTINCT order_id)                        AS pair_frequency,
    ROUND(COUNT(DISTINCT order_id) * 100.0
        / (SELECT COUNT(DISTINCT order_id)
           FROM gold.fact_orders
           WHERE channel           = 'Website'
             AND is_negative_price = 0)
    , 2)                                            AS support_pct
FROM category_pairs
GROUP BY category_a, category_b
ORDER BY pair_frequency DESC;


-- Step 4: Average basket size and value
SELECT
    COUNT(DISTINCT f.order_id)                      AS total_orders,
    ROUND(
        CAST(COUNT(*) AS FLOAT)
        / COUNT(DISTINCT f.order_id)
    , 2)                                            AS avg_items_per_basket,
    ROUND(
        SUM(f.total_amount_recalc_usd)
        / COUNT(DISTINCT f.order_id)
    , 2)                                            AS avg_basket_value_usd,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue_usd
FROM gold.fact_orders f
WHERE f.channel           = 'Website'
  AND f.is_negative_price = 0;


/********************************************************************************************
 DELIVERABLE 3 — PROMO CODE EFFECTIVENESS
********************************************************************************************/

-- 3.1 Overall promo vs non-promo comparison
SELECT
    CASE
        WHEN pr.promo_code = 'NO PROMO' THEN 'No Promo'
        ELSE 'Promo Applied'
    END                                             AS promo_applied,
    COUNT(*)                                        AS order_lines,
    ROUND(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER ()
    , 2)                                            AS pct_of_orders,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(AVG(CAST(f.quantity AS FLOAT)), 2)        AS avg_quantity
FROM gold.fact_orders f
JOIN gold.dim_promo pr ON f.promo_key = pr.promo_key
WHERE f.channel           = 'Mobile App'
  AND f.is_negative_price = 0
GROUP BY
    CASE
        WHEN pr.promo_code = 'NO PROMO' THEN 'No Promo'
        ELSE 'Promo Applied'
    END;


-- 3.2 Revenue and AOV by promo code
SELECT
    pr.promo_code,
    pr.promo_type,
    pr.discount_pct,
    COUNT(*)                                        AS redemptions,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
    , 2)                                            AS pct_of_promo_revenue
FROM gold.fact_orders f
JOIN gold.dim_promo pr ON f.promo_key = pr.promo_key
WHERE f.channel           = 'Mobile App'
  AND f.is_negative_price = 0
  AND pr.promo_code       != 'NO PROMO'
GROUP BY pr.promo_code, pr.promo_type, pr.discount_pct
ORDER BY total_revenue DESC;


-- 3.3 Revenue and AOV by promo type
SELECT
    pr.promo_type,
    COUNT(*)                                        AS redemptions,
    COUNT(DISTINCT f.customer_key)                  AS unique_customers,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(SUM(
        f.total_amount_recalc_usd
        - f.total_amount_usd
    ), 2)                                           AS estimated_discount_given
FROM gold.fact_orders f
JOIN gold.dim_promo pr ON f.promo_key = pr.promo_key
WHERE f.channel           = 'Mobile App'
  AND f.is_negative_price = 0
  AND pr.promo_code       != 'NO PROMO'
GROUP BY pr.promo_type
ORDER BY total_revenue DESC;


-- 3.4 Promo effectiveness by product category
SELECT
    p.category,
    pr.promo_type,
    COUNT(*)                                        AS redemptions,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov
FROM gold.fact_orders f
JOIN gold.dim_promo   pr ON f.promo_key   = pr.promo_key
JOIN gold.dim_product p  ON f.product_key = p.product_key
WHERE f.channel           = 'Mobile App'
  AND f.is_negative_price = 0
  AND pr.promo_code       != 'NO PROMO'
GROUP BY p.category, pr.promo_type
ORDER BY p.category, total_revenue DESC;


-- 3.5 Promo usage by customer spend tier
WITH customer_spend AS (
    SELECT
        f.customer_key,
        ROUND(SUM(f.total_amount_recalc_usd), 2)    AS total_spend,
        NTILE(5) OVER (
            ORDER BY SUM(f.total_amount_recalc_usd) ASC
        )                                           AS spend_tier
    FROM gold.fact_orders f
    WHERE f.channel           = 'Mobile App'
      AND f.is_negative_price = 0
      AND f.customer_key IS NOT NULL
    GROUP BY f.customer_key
)
SELECT
    CASE
        WHEN cs.spend_tier = 5 THEN 'High Value (Top 20%)'
        WHEN cs.spend_tier = 4 THEN 'Mid-High Value'
        WHEN cs.spend_tier = 3 THEN 'Mid Value'
        ELSE 'Low Value (Bottom 40%)'
    END                                             AS customer_tier,
    CASE
        WHEN pr.promo_code = 'NO PROMO' THEN 'No Promo'
        ELSE 'Promo Applied'
    END                                             AS promo_applied,
    COUNT(*)                                        AS order_lines,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue
FROM gold.fact_orders f
JOIN gold.dim_promo    pr ON f.promo_key    = pr.promo_key
JOIN customer_spend    cs ON f.customer_key = cs.customer_key
WHERE f.channel           = 'Mobile App'
  AND f.is_negative_price = 0
GROUP BY
    CASE
        WHEN cs.spend_tier = 5 THEN 'High Value (Top 20%)'
        WHEN cs.spend_tier = 4 THEN 'Mid-High Value'
        WHEN cs.spend_tier = 3 THEN 'Mid Value'
        ELSE 'Low Value (Bottom 40%)'
    END,
    CASE
        WHEN pr.promo_code = 'NO PROMO' THEN 'No Promo'
        ELSE 'Promo Applied'
    END
ORDER BY customer_tier, promo_applied;


/********************************************************************************************
 DELIVERABLE 4 — $500K AD SPEND RECOMMENDATION
********************************************************************************************/

-- 4.1 Revenue share by channel
SELECT
    channel,
    COUNT(DISTINCT order_id)                        AS total_orders,
    ROUND(SUM(total_amount_recalc_usd), 2)          AS total_revenue,
    ROUND(
        SUM(total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(total_amount_recalc_usd)) OVER ()
    , 2)                                            AS revenue_share_pct,
    ROUND(
        SUM(total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(total_amount_recalc_usd)) OVER ()
        * 500000 / 100
    , 0)                                            AS recommended_budget_usd
FROM gold.fact_orders
WHERE is_negative_price = 0
GROUP BY channel
ORDER BY total_revenue DESC;


-- 4.2 Revenue share by geography
SELECT
    g.country,
    COUNT(DISTINCT f.order_id)                      AS total_orders,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
    , 2)                                            AS revenue_share_pct,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
        * 500000 / 100
    , 0)                                            AS recommended_budget_usd
FROM gold.fact_orders f
JOIN gold.dim_geography g ON f.geography_key = g.geography_key
WHERE f.is_negative_price = 0
  AND g.country != 'N/A'
GROUP BY g.country
ORDER BY total_revenue DESC;


-- 4.3 Revenue and AOV by device type
SELECT
    dv.device_type,
    COUNT(DISTINCT f.order_id)                      AS total_orders,
    COUNT(DISTINCT f.customer_key)                  AS unique_customers,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
    , 2)                                            AS revenue_share_pct,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
        * 500000 / 100
    , 0)                                            AS recommended_budget_usd
FROM gold.fact_orders f
JOIN gold.dim_device dv ON f.device_key = dv.device_key
WHERE f.channel           = 'Mobile App'
  AND f.is_negative_price = 0
  AND dv.device_type      != 'N/A'
GROUP BY dv.device_type
ORDER BY total_revenue DESC;


-- 4.4 Revenue by category
SELECT
    p.category,
    COUNT(DISTINCT f.order_id)                      AS total_orders,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
    , 2)                                            AS revenue_share_pct,
    ROUND(
        SUM(f.total_amount_recalc_usd) * 100.0
        /
        SUM(SUM(f.total_amount_recalc_usd)) OVER ()
        * 500000 / 100
    , 0)                                            AS category_budget_usd
FROM gold.fact_orders f
JOIN gold.dim_product p ON f.product_key = p.product_key
WHERE f.is_negative_price = 0
GROUP BY p.category
ORDER BY total_revenue DESC;


-- 4.5 Cross-channel customer value
SELECT
    c.preferred_channel,
    COUNT(DISTINCT f.customer_key)                  AS unique_customers,
    COUNT(DISTINCT f.order_id)                      AS total_orders,
    ROUND(SUM(f.total_amount_recalc_usd), 2)        AS total_revenue,
    ROUND(AVG(f.total_amount_recalc_usd), 2)        AS aov,
    ROUND(
        SUM(f.total_amount_recalc_usd)
        / COUNT(DISTINCT f.customer_key)
    , 2)                                            AS revenue_per_customer
FROM gold.fact_orders f
JOIN gold.dim_customer c ON f.customer_key = c.customer_key
WHERE f.is_negative_price = 0
  AND c.is_guest          = 0
GROUP BY c.preferred_channel
ORDER BY revenue_per_customer DESC;

