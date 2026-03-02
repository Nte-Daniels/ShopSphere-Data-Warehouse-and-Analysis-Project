/********************************************************************************************
 SCRIPT NAME : SILVER LAYER — EXPLORATION & DATA QUALITY CHECKS
 SOURCE      : bronze.website_orders
 DESCRIPTION :
     PRE-TRANSFORMATION CHECKS TO UNDERSTAND DATA QUALITY ISSUES
     IN THE RAW BRONZE DATA BEFORE SILVER LAYER CLEANING.
********************************************************************************************/

SELECT * FROM bronze.website_orders
SELECT * FROM bronze.mobile_app_transactions


------------------------------------------------------------
-- 1. DUPLICATE ORDER LINES
--    Same order_id + product_id appearing more than once
------------------------------------------------------------

SELECT
    order_id,
    product_id,
    COUNT(*) AS Duplicate_count
FROM bronze.website_orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY Duplicate_count DESC;


------------------------------------------------------------
-- 2. NULL CUSTOMER NAMES
------------------------------------------------------------

SELECT
    COUNT(*)                                                   AS Total_rows,
    SUM(CASE WHEN Customer_name IS NULL THEN 1 ELSE 0 END)     AS Null_names,
    SUM(CASE WHEN Customer_name IS NULL THEN 1 ELSE 0 END) * 100     
       / COUNT(*)                                              AS Null_pct
FROM bronze.website_orders


------------------------------------------------------------
-- 3. NULL SHIPPING ADDRESSES
------------------------------------------------------------
SELECT
    COUNT(*)                                                   AS total_rows,
    SUM(CASE WHEN shipping_address IS NULL THEN 1 ELSE 0 END)  AS null_addresses,
    SUM(CASE WHEN shipping_address IS NULL THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)                                             AS null_pct
FROM bronze.website_orders;


------------------------------------------------------------
-- 4. MIXED DATE FORMATS
--    Identify all distinct date patterns present
------------------------------------------------------------

SELECT
    order_date,
    CASE
        WHEN order_date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN 'YYYY-MM-DD'
        WHEN order_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN 'MM/DD/YYYY'
        WHEN order_date LIKE '[0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9][0-9][0-9]'
            THEN 'DD-Mon-YYYY'
        WHEN order_date LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]'
            THEN 'YYYY/MM/DD'
        WHEN order_date LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9]'
            THEN 'DD.MM.YYYY'
        ELSE 'UNKNOWN'
    END AS detected_format
FROM
    bronze.website_orders
ORDER BY detected_format;


-- Count by format
SELECT
    CASE
        WHEN order_date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN 'YYYY-MM-DD'
        WHEN order_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN 'MM/DD/YYYY'
        WHEN order_date LIKE '[0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9][0-9][0-9]'
            THEN 'DD-Mon-YYYY'
        WHEN order_date LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]'
            THEN 'YYYY/MM/DD'
        WHEN order_date LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9]'
            THEN 'DD.MM.YYYY'
        ELSE 'UNKNOWN'
    END AS detected_format,
    COUNT(*) AS record_count
FROM bronze.website_orders
GROUP BY
    CASE
        WHEN order_date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
            THEN 'YYYY-MM-DD'
        WHEN order_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
            THEN 'MM/DD/YYYY'
        WHEN order_date LIKE '[0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9][0-9][0-9]'
            THEN 'DD-Mon-YYYY'
        WHEN order_date LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]'
            THEN 'YYYY/MM/DD'
        WHEN order_date LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9]'
            THEN 'DD.MM.YYYY'
        ELSE 'UNKNOWN'
    END
ORDER BY record_count DESC;


------------------------------------------------------------
-- 5. INCONSISTENT ORDER STATUS VALUES
------------------------------------------------------------
SELECT DISTINCT
    order_status,
    COUNT(*) AS record_count
FROM bronze.website_orders
GROUP BY order_status
ORDER BY record_count DESC;


------------------------------------------------------------
-- 6. NEGATIVE UNIT PRICES
------------------------------------------------------------
SELECT
    COUNT(*) AS negative_price_count
FROM bronze.website_orders
WHERE TRY_CAST(unit_price AS DECIMAL(10,2)) < 0;

-- Preview the records
SELECT
    order_id,
    product_name,
    unit_price,
    quantity,
    total_amount
FROM bronze.website_orders
WHERE TRY_CAST(unit_price AS DECIMAL(10,2)) < 0;

------------------------------------------------------------
-- 7. TOTAL AMOUNT MISMATCH
--    total_amount should equal (quantity * unit_price) - discount + shipping_cost
------------------------------------------------------------
SELECT
    order_id,
    product_name,
    quantity,
    unit_price,
    discount,
    shipping_cost,
    total_amount,
    ROUND(
        TRY_CAST(quantity AS INT)
        * TRY_CAST(unit_price AS DECIMAL(10,2))
        - TRY_CAST(discount AS DECIMAL(10,2))
        + TRY_CAST(shipping_cost AS DECIMAL(10,2)),
    2) AS expected_total,
    ROUND(
        ABS(
            TRY_CAST(total_amount AS DECIMAL(10,2)) -
            (
                TRY_CAST(quantity AS INT)
                * TRY_CAST(unit_price AS DECIMAL(10,2))
                - TRY_CAST(discount AS DECIMAL(10,2))
                + TRY_CAST(shipping_cost AS DECIMAL(10,2))
            )
        ),
    2) AS variance
FROM bronze.website_orders
WHERE
    ABS(
        TRY_CAST(total_amount AS DECIMAL(10,2)) -
        (
            TRY_CAST(quantity AS INT)
            * TRY_CAST(unit_price AS DECIMAL(10,2))
            - TRY_CAST(discount AS DECIMAL(10,2))
            + TRY_CAST(shipping_cost AS DECIMAL(10,2))
        )
    ) > 0.01
ORDER BY variance DESC;


------------------------------------------------------------
-- 8. MESSY CURRENCY VALUES
------------------------------------------------------------
SELECT DISTINCT
    currency,
    COUNT(*) AS record_count
FROM bronze.website_orders
GROUP BY currency
ORDER BY record_count DESC;


------------------------------------------------------------
-- 9. INCONSISTENT PRODUCT ID FORMATS
------------------------------------------------------------
SELECT DISTINCT
    product_id,
    LEFT(product_id, PATINDEX('%[0-9]%', product_id) - 1) AS prefix_detected
FROM bronze.website_orders
ORDER BY prefix_detected;

-- Count by format pattern
SELECT
    CASE
        WHEN product_id LIKE 'PROD-[0-9]%' THEN 'PROD-NNN'
        WHEN product_id LIKE 'prod-[0-9]%' THEN 'prod-NNN'
        WHEN product_id LIKE 'P[0-9]%'     THEN 'PNNN'
        WHEN product_id LIKE 'PROD[0-9]%'  THEN 'PRODNNN'
        ELSE 'OTHER'
    END AS format_pattern,
    COUNT(*) AS record_count
FROM bronze.website_orders
GROUP BY
    CASE
        WHEN product_id LIKE 'PROD-[0-9]%' THEN 'PROD-NNN'
        WHEN product_id LIKE 'prod-[0-9]%' THEN 'prod-NNN'
        WHEN product_id LIKE 'P[0-9]%'     THEN 'PNNN'
        WHEN product_id LIKE 'PROD[0-9]%'  THEN 'PRODNNN'
        ELSE 'OTHER'
    END
ORDER BY record_count DESC;


------------------------------------------------------------
-- 10. CUSTOMER EMAIL CASING
------------------------------------------------------------
SELECT DISTINCT
    customer_email
FROM bronze.website_orders
WHERE customer_email != LOWER(customer_email)
ORDER BY customer_email;


------------------------------------------------------------
-- 11. UNWANTED SPACES IN KEY TEXT FIELDS
------------------------------------------------------------
SELECT customer_name
FROM bronze.website_orders
WHERE customer_name != TRIM(customer_name);

SELECT product_name
FROM bronze.website_orders
WHERE product_name != TRIM(product_name);


/********************************************************************************************
 SCRIPT NAME : SILVER LAYER — EXPLORATION & DATA QUALITY CHECKS
 SOURCE      : bronze.mobile_app_transactions
 DESCRIPTION :
     PRE-TRANSFORMATION CHECKS TO UNDERSTAND DATA QUALITY ISSUES
     BEFORE SILVER LAYER CLEANING.
********************************************************************************************/

------

------------------------------------------------------------
-- 1. DUPLICATE TRANSACTIONS
------------------------------------------------------------
SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM bronze.mobile_app_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

------------------------------------------------------------
-- 2. NULL USER EMAILS (~8% expected)
------------------------------------------------------------
SELECT
    COUNT(*)                                              AS total_rows,
    SUM(CASE WHEN user_email IS NULL THEN 1 ELSE 0 END)  AS null_emails,
    SUM(CASE WHEN user_email IS NULL THEN 1 ELSE 0 END) * 100.0
        / COUNT(*)                                        AS null_pct
FROM bronze.mobile_app_transactions;


------------------------------------------------------------
-- 3. MIXED TIMESTAMP FORMATS
------------------------------------------------------------
SELECT
    CASE
        WHEN transaction_timestamp LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] %'
            THEN 'YYYY-MM-DD HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %'
            THEN 'MM/DD/YYYY HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9][0-9][0-9] %'
            THEN 'DD-Mon-YYYY HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9] %'
            THEN 'DD.MM.YYYY HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9] %'
            THEN 'YYYY/MM/DD HH:MM:SS'
        WHEN TRY_CAST(transaction_timestamp AS BIGINT) IS NOT NULL
            THEN 'Unix Timestamp'
        ELSE 'UNKNOWN'
    END AS detected_format,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
GROUP BY
    CASE
        WHEN transaction_timestamp LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] %'
            THEN 'YYYY-MM-DD HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %'
            THEN 'MM/DD/YYYY HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9][0-9][0-9] %'
            THEN 'DD-Mon-YYYY HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9] %'
            THEN 'DD.MM.YYYY HH:MM:SS'
        WHEN transaction_timestamp LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9] %'
            THEN 'YYYY/MM/DD HH:MM:SS'
        WHEN TRY_CAST(transaction_timestamp AS BIGINT) IS NOT NULL
            THEN 'Unix Timestamp'
        ELSE 'UNKNOWN'
    END
ORDER BY record_count DESC;


------------------------------------------------------------
-- 4. DELIVERY STATUS VARIANTS
------------------------------------------------------------
SELECT
    delivery_status,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
GROUP BY delivery_status
ORDER BY record_count DESC;


------------------------------------------------------------
-- 5. ITEM CATEGORY VARIANTS
--    Expect aliases: Tech, Apparel, H&K, Fitness etc.
------------------------------------------------------------
SELECT
    item_category,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
GROUP BY item_category
ORDER BY record_count DESC;


------------------------------------------------------------
-- 6. GROSS TOTAL MISMATCH
--    gross_total should equal (qty * price) + delivery_fee
------------------------------------------------------------
SELECT
    COUNT(*) AS mismatch_count
FROM bronze.mobile_app_transactions
WHERE
    ABS(
        ISNULL(TRY_CAST(gross_total AS DECIMAL(10,2)), 0)
        - (
            ISNULL(TRY_CAST(qty AS INT), 0)
            * ISNULL(TRY_CAST(price AS DECIMAL(10,2)), 0)
            + ISNULL(TRY_CAST(delivery_fee AS DECIMAL(10,2)), 0)
        )
    ) > 0.01;


------------------------------------------------------------
-- 7. NEGATIVE PRICES
------------------------------------------------------------
SELECT
    COUNT(*) AS negative_price_count
FROM bronze.mobile_app_transactions
WHERE TRY_CAST(price AS DECIMAL(10,2)) < 0;


------------------------------------------------------------
-- 8. CURRENCY CODE VARIANTS
------------------------------------------------------------
SELECT
    currency_code,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
GROUP BY currency_code
ORDER BY record_count DESC;


------------------------------------------------------------
-- 9. ITEM CODE FORMAT VARIANTS
------------------------------------------------------------
SELECT
    CASE
        WHEN item_code LIKE 'APP-[0-9]%'     THEN 'APP-NNN'
        WHEN item_code LIKE 'MOB-PROD-[0-9]%' THEN 'MOB-PROD-NNN'
        WHEN item_code LIKE 'M[0-9]%'         THEN 'MNNN'
        WHEN item_code LIKE 'PROD-[0-9]%'     THEN 'PROD-NNN'
        WHEN item_code LIKE 'PROD[0-9]%'      THEN 'PRODNNN'
        ELSE 'OTHER'
    END AS format_pattern,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
GROUP BY
    CASE
        WHEN item_code LIKE 'APP-[0-9]%'      THEN 'APP-NNN'
        WHEN item_code LIKE 'MOB-PROD-[0-9]%' THEN 'MOB-PROD-NNN'
        WHEN item_code LIKE 'M[0-9]%'         THEN 'MNNN'
        WHEN item_code LIKE 'PROD-[0-9]%'     THEN 'PROD-NNN'
        WHEN item_code LIKE 'PROD[0-9]%'      THEN 'PRODNNN'
        ELSE 'OTHER'
    END
ORDER BY record_count DESC;


------------------------------------------------------------
-- 10. DEVICE TYPE VARIANTS
------------------------------------------------------------
SELECT
    device_type,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
GROUP BY device_type
ORDER BY record_count DESC;

------------------------------------------------------------
-- 11. PROMO CODE SAMPLE
--     Check casing and special character mess
------------------------------------------------------------
SELECT DISTINCT
    promo_code,
    COUNT(*) AS record_count
FROM bronze.mobile_app_transactions
WHERE promo_code IS NOT NULL
GROUP BY promo_code
ORDER BY record_count DESC;

------------------------------------------------------------
-- 12. UNWANTED SPACES
------------------------------------------------------------
SELECT COUNT(*) AS spaces_in_description
FROM bronze.mobile_app_transactions
WHERE item_description != TRIM(item_description);

SELECT COUNT(*) AS spaces_in_category
FROM bronze.mobile_app_transactions
WHERE item_category != TRIM(item_category);


-- What are the UNKNOWN timestamp formats?
SELECT DISTINCT TOP 20
    transaction_timestamp
FROM bronze.mobile_app_transactions
WHERE transaction_timestamp NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] %'
  AND TRY_CAST(transaction_timestamp AS BIGINT) IS NULL
ORDER BY transaction_timestamp;

-- What are the OTHER item code formats?
SELECT DISTINCT
    item_code
FROM bronze.mobile_app_transactions
WHERE item_code NOT LIKE 'APP-[0-9]%'
  AND item_code NOT LIKE 'MOB-PROD-[0-9]%'
  AND item_code NOT LIKE 'M[0-9]%'
  AND item_code NOT LIKE 'PROD-[0-9]%'
  AND item_code NOT LIKE 'PROD[0-9]%'
ORDER BY item_code;


------------------------------------------------------------
-- POST-LOAD QUALITY CHECKS
------------------------------------------------------------

-- 1. Duplicates (should return 0 rows)
SELECT order_id, product_id, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- 2. Unparsed dates (should return 0)
SELECT COUNT(*) AS unparsed_dates
FROM silver.website_orders
WHERE order_date IS NULL
  AND order_date_raw IS NOT NULL;

-- 3. Order status distribution (should be 6 clean values only)
SELECT DISTINCT order_status, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY order_status
ORDER BY cnt DESC;

-- 4. Negative price flag distribution
SELECT is_negative_price, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY is_negative_price;

-- 5. Total mismatch flag distribution
SELECT is_total_mismatch, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY is_total_mismatch;

-- 6. Currency (┬ú should now be gone — only USD, GBP, EUR, Unknown)
SELECT DISTINCT currency, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY currency
ORDER BY cnt DESC;

-- 7. Product ID format check (should return 0 invalid rows)
SELECT product_id
FROM silver.website_orders
WHERE product_id NOT LIKE 'PROD-[0-9][0-9][0-9]'
ORDER BY product_id;

-- 8. Null customer names (should return 0)
SELECT COUNT(*) AS remaining_null_names
FROM silver.website_orders
WHERE customer_name IS NULL OR customer_name = '';

-- 9. Null shipping addresses (should return 0)
SELECT COUNT(*) AS remaining_null_addresses
FROM silver.website_orders
WHERE shipping_address IS NULL OR shipping_address = '';

-- 10. Final row count
SELECT COUNT(*) AS silver_row_count FROM silver.website_orders;

------------------------------------------------------------
-- POST-LOAD QUALITY CHECKS
------------------------------------------------------------

-- 1. Duplicates (should return 0 rows)
SELECT transaction_id, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 2. Unparsed timestamps (should return 0)
SELECT COUNT(*) AS unparsed_timestamps
FROM silver.mobile_app_transactions
WHERE transaction_timestamp IS NULL
  AND transaction_timestamp_raw IS NOT NULL;

-- 3. Delivery status distribution (5 canonical values only)
SELECT DISTINCT delivery_status, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY delivery_status
ORDER BY cnt DESC;

-- 4. Item category distribution (6 canonical values only)
SELECT DISTINCT item_category, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY item_category
ORDER BY cnt DESC;

-- 5. Total mismatch flag distribution
SELECT is_total_mismatch, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY is_total_mismatch;

-- 6. Currency distribution (USD, GBP, EUR, Unknown only)
SELECT DISTINCT currency_code, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY currency_code
ORDER BY cnt DESC;

-- 7. Item code format check (should return 0 invalid rows)
SELECT item_code
FROM silver.mobile_app_transactions
WHERE item_code NOT LIKE 'PROD-[0-9][0-9][0-9]'
ORDER BY item_code;

-- 8. Null user emails (should return 0)
SELECT COUNT(*) AS remaining_null_emails
FROM silver.mobile_app_transactions
WHERE user_email IS NULL OR user_email = '';

-- 9. Device type distribution (iOS and Android only)
SELECT DISTINCT device_type, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY device_type
ORDER BY cnt DESC;

-- 10. Promo code sample (all uppercase, no special chars)
SELECT DISTINCT promo_code, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
WHERE promo_code IS NOT NULL
GROUP BY promo_code
ORDER BY cnt DESC;

-- 11. Row count sanity check
SELECT COUNT(*) AS silver_row_count
FROM silver.mobile_app_transactions;











------------------------------------------------------------
-- GOLD LAYER — PRE-BUILD EXPLORATION
------------------------------------------------------------

-- 1. Customer: how many unique emails across both channels
SELECT COUNT(DISTINCT customer_email) AS unique_web_customers
FROM silver.website_orders
WHERE customer_email IS NOT NULL
  AND customer_email != '';

SELECT COUNT(DISTINCT user_email) AS unique_app_customers
FROM silver.mobile_app_transactions
WHERE user_email != 'Guest';

-- 2. How many customers appear in BOTH channels
SELECT COUNT(DISTINCT w.customer_email) AS cross_channel_customers
FROM silver.website_orders w
INNER JOIN silver.mobile_app_transactions m
    ON w.customer_email = m.user_email
WHERE w.customer_email IS NOT NULL
  AND m.user_email != 'Guest';

-- 3. Product: confirm both channels share same PROD-NNN space
SELECT COUNT(DISTINCT product_id) AS web_products
FROM silver.website_orders;

SELECT COUNT(DISTINCT item_code) AS app_products
FROM silver.mobile_app_transactions;

-- 4. Geography: distinct countries from web
SELECT DISTINCT country, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY country
ORDER BY cnt DESC;

-- 5. Geography: distinct regions from app
SELECT DISTINCT region, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY region
ORDER BY cnt DESC;

-- 6. Payment: distinct methods across both channels
SELECT DISTINCT payment_method, COUNT(*) AS cnt
FROM silver.website_orders
GROUP BY payment_method
ORDER BY cnt DESC;

SELECT DISTINCT payment_type, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY payment_type
ORDER BY cnt DESC;

-- 7. Promo: distinct codes from app
SELECT DISTINCT promo_code, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
WHERE promo_code IS NOT NULL
  AND promo_code != ''
GROUP BY promo_code
ORDER BY cnt DESC;

-- 8. Device: distinct types from app
SELECT DISTINCT device_type, COUNT(*) AS cnt
FROM silver.mobile_app_transactions
GROUP BY device_type
ORDER BY cnt DESC;

-- 9. Date range across both channels
SELECT
    MIN(order_date) AS web_min_date,
    MAX(order_date) AS web_max_date
FROM silver.website_orders;

SELECT
    MIN(CAST(transaction_timestamp AS DATE)) AS app_min_date,
    MAX(CAST(transaction_timestamp AS DATE)) AS app_max_date
FROM silver.mobile_app_transactions;



------------------------------------------------------------
-- POST-LOAD QUALITY CHECKS
------------------------------------------------------------

-- 1. Row counts across all tables
SELECT 'dim_date'        AS table_name, COUNT(*) AS row_count FROM gold.dim_date
UNION ALL
SELECT 'dim_customer',                  COUNT(*) FROM gold.dim_customer
UNION ALL
SELECT 'dim_product',                   COUNT(*) FROM gold.dim_product
UNION ALL
SELECT 'dim_geography',                 COUNT(*) FROM gold.dim_geography
UNION ALL
SELECT 'dim_payment',                   COUNT(*) FROM gold.dim_payment
UNION ALL
SELECT 'dim_promo',                     COUNT(*) FROM gold.dim_promo
UNION ALL
SELECT 'dim_device',                    COUNT(*) FROM gold.dim_device
UNION ALL
SELECT 'fact_orders',                   COUNT(*) FROM gold.fact_orders;



-- 2. Confirm no orphaned FK keys in fact_orders
SELECT COUNT(*) AS null_date_keys     FROM gold.fact_orders WHERE date_key     IS NULL;
SELECT COUNT(*) AS null_customer_keys FROM gold.fact_orders WHERE customer_key IS NULL;
SELECT COUNT(*) AS null_product_keys  FROM gold.fact_orders WHERE product_key  IS NULL;
SELECT COUNT(*) AS null_payment_keys  FROM gold.fact_orders WHERE payment_key  IS NULL;
SELECT COUNT(*) AS null_promo_keys    FROM gold.fact_orders WHERE promo_key    IS NULL;
SELECT COUNT(*) AS null_device_keys   FROM gold.fact_orders WHERE device_key   IS NULL;

-- 3. Channel split in fact_orders
SELECT channel, COUNT(*) AS row_count
FROM gold.fact_orders
GROUP BY channel;


-- 4. Currency distribution in fact
SELECT currency, COUNT(*) AS cnt
FROM gold.fact_orders
GROUP BY currency
ORDER BY cnt DESC;



-- 5. USD conversion sanity check
SELECT TOP 10
    order_id,
    channel,
    currency,
    total_amount,
    total_amount_usd
FROM gold.fact_orders
WHERE currency != 'USD'
ORDER BY total_amount DESC;


-- 6. Confirm dim_promo types loaded correctly
SELECT promo_code, discount_pct, promo_type
FROM gold.dim_promo
ORDER BY promo_type;

-- 7. Confirm dim_customer preferred_channel distribution
SELECT preferred_channel, COUNT(*) AS cnt
FROM gold.dim_customer
GROUP BY preferred_channel
ORDER BY cnt DESC;

-- 8. Confirm dim_payment categories
SELECT payment_method, payment_category
FROM gold.dim_payment
ORDER BY payment_category;

-- 9. Date range in fact
SELECT
    MIN(d.full_date) AS earliest_order,
    MAX(d.full_date) AS latest_order
FROM gold.fact_orders f
JOIN gold.dim_date d ON f.date_key = d.date_key;

-- 10. Total revenue sanity check
SELECT
    channel,
    COUNT(*)                        AS total_orders,
    SUM(total_amount_usd)           AS total_revenue_usd,
    AVG(total_amount_usd)           AS avg_order_value_usd
FROM gold.fact_orders
WHERE is_negative_price = 0
GROUP BY channel;
