/********************************************************************************************
 SCRIPT NAME : GOLD LAYER — FULL DDL & LOAD
 DESCRIPTION :
     CREATES ALL DIMENSION TABLES AND FACT TABLE FOR THE SHOPSPHERE
     STAR SCHEMA. LOADS DATA FROM SILVER LAYER.
 SCHEMA      : gold
 TABLES      : dim_date, dim_customer, dim_product, dim_geography,
               dim_payment, dim_promo, dim_device, fact_orders
********************************************************************************************/

------------------------------------------------------------
-- DIM 1: gold.dim_date
------------------------------------------------------------
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DROP TABLE gold.dim_date;
GO

CREATE TABLE gold.dim_date (
    date_key        INT          NOT NULL,   -- YYYYMMDD format
    full_date       DATE         NOT NULL,
    day_of_week     NVARCHAR(10) NOT NULL,
    day_number      INT          NOT NULL,
    week_number     INT          NOT NULL,
    month_number    INT          NOT NULL,
    month_name      NVARCHAR(10) NOT NULL,
    quarter_number  INT          NOT NULL,
    quarter_name    NVARCHAR(10) NOT NULL,
    year_number     INT          NOT NULL,
    is_weekend      BIT          NOT NULL,
    CONSTRAINT PK_gold_dim_date PRIMARY KEY (date_key)
);
GO

------------------------------------------------------------
-- DIM 2: gold.dim_customer
------------------------------------------------------------
IF OBJECT_ID('gold.dim_customer', 'U') IS NOT NULL
    DROP TABLE gold.dim_customer;
GO

CREATE TABLE gold.dim_customer (
    customer_key        INT IDENTITY(1,1) NOT NULL,
    customer_email      NVARCHAR(255)     NOT NULL,
    customer_name       NVARCHAR(255)     NULL,
    preferred_channel   NVARCHAR(20)      NULL,   -- Website / Mobile App / Both
    is_guest            BIT               NOT NULL DEFAULT 0,
    dwh_load_timestamp  DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_gold_dim_customer PRIMARY KEY (customer_key)
);
GO

------------------------------------------------------------
-- DIM 3: gold.dim_product
------------------------------------------------------------
IF OBJECT_ID('gold.dim_product', 'U') IS NOT NULL
    DROP TABLE gold.dim_product;
GO

CREATE TABLE gold.dim_product (
    product_key         INT IDENTITY(1,1) NOT NULL,
    product_id          NVARCHAR(20)      NOT NULL,   -- PROD-NNN
    product_name        NVARCHAR(255)     NULL,
    category            NVARCHAR(100)     NULL,
    dwh_load_timestamp  DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_gold_dim_product PRIMARY KEY (product_key)
);
GO

------------------------------------------------------------
-- DIM 4: gold.dim_geography
------------------------------------------------------------
IF OBJECT_ID('gold.dim_geography', 'U') IS NOT NULL
    DROP TABLE gold.dim_geography;
GO

CREATE TABLE gold.dim_geography (
    geography_key       INT IDENTITY(1,1) NOT NULL,
    country             NVARCHAR(100)     NOT NULL,
    region              NVARCHAR(100)     NULL,
    dwh_load_timestamp  DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_gold_dim_geography PRIMARY KEY (geography_key)
);
GO

------------------------------------------------------------
-- DIM 5: gold.dim_payment
------------------------------------------------------------
IF OBJECT_ID('gold.dim_payment', 'U') IS NOT NULL
    DROP TABLE gold.dim_payment;
GO

CREATE TABLE gold.dim_payment (
    payment_key         INT IDENTITY(1,1) NOT NULL,
    payment_method      NVARCHAR(100)     NOT NULL,
    payment_category    NVARCHAR(50)      NULL,   -- Digital Wallet / Card / Other
    dwh_load_timestamp  DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_gold_dim_payment PRIMARY KEY (payment_key)
);
GO

------------------------------------------------------------
-- DIM 6: gold.dim_promo
------------------------------------------------------------
IF OBJECT_ID('gold.dim_promo', 'U') IS NOT NULL
    DROP TABLE gold.dim_promo;
GO

CREATE TABLE gold.dim_promo (
    promo_key           INT IDENTITY(1,1) NOT NULL,
    promo_code          NVARCHAR(50)      NOT NULL,
    discount_pct        DECIMAL(5,2)      NULL,   -- extracted from code where possible
    promo_type          NVARCHAR(50)      NULL,   -- Seasonal / Welcome / Flash / VIP / Other
    dwh_load_timestamp  DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_gold_dim_promo PRIMARY KEY (promo_key)
);
GO

------------------------------------------------------------
-- DIM 7: gold.dim_device
------------------------------------------------------------
IF OBJECT_ID('gold.dim_device', 'U') IS NOT NULL
    DROP TABLE gold.dim_device;
GO

CREATE TABLE gold.dim_device (
    device_key          INT IDENTITY(1,1) NOT NULL,
    device_type         NVARCHAR(20)      NOT NULL,   -- iOS / Android / N/A
    app_version         NVARCHAR(20)      NULL,
    dwh_load_timestamp  DATETIME          NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_gold_dim_device PRIMARY KEY (device_key)
);
GO

------------------------------------------------------------
-- FACT: gold.fact_orders
------------------------------------------------------------
IF OBJECT_ID('gold.fact_orders', 'U') IS NOT NULL
    DROP TABLE gold.fact_orders;
GO

CREATE TABLE gold.fact_orders (
    order_key                INT IDENTITY(1,1) NOT NULL,

    -- Surrogate FKs
    date_key                 INT               NULL,
    customer_key             INT               NULL,
    product_key              INT               NULL,
    geography_key            INT               NULL,
    payment_key              INT               NULL,
    promo_key                INT               NULL,
    device_key               INT               NULL,

    -- Natural keys
    order_id                 NVARCHAR(50)      NOT NULL,
    channel                  NVARCHAR(20)      NOT NULL,

    -- Measures
    quantity                 INT               NULL,
    unit_price               DECIMAL(10,2)     NULL,
    discount                 DECIMAL(10,2)     NULL,
    shipping_cost            DECIMAL(10,2)     NULL,
    total_amount             DECIMAL(10,2)     NULL,
    total_amount_usd         DECIMAL(10,2)     NULL,    -- source total converted to USD
    total_amount_recalc_usd  DECIMAL(10,2)     NULL,    -- recalculated from components

    -- Order metadata
    order_status             NVARCHAR(50)      NULL,
    currency                 NVARCHAR(10)      NULL,

    -- Data quality flags
    is_negative_price        BIT               NOT NULL DEFAULT 0,
    is_total_mismatch        BIT               NOT NULL DEFAULT 0,

    -- Audit
    dwh_load_timestamp       DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_gold_fact_orders PRIMARY KEY (order_key),
    CONSTRAINT FK_fact_date      FOREIGN KEY (date_key)      REFERENCES gold.dim_date(date_key),
    CONSTRAINT FK_fact_customer  FOREIGN KEY (customer_key)  REFERENCES gold.dim_customer(customer_key),
    CONSTRAINT FK_fact_product   FOREIGN KEY (product_key)   REFERENCES gold.dim_product(product_key),
    CONSTRAINT FK_fact_geography FOREIGN KEY (geography_key) REFERENCES gold.dim_geography(geography_key),
    CONSTRAINT FK_fact_payment   FOREIGN KEY (payment_key)   REFERENCES gold.dim_payment(payment_key),
    CONSTRAINT FK_fact_promo     FOREIGN KEY (promo_key)     REFERENCES gold.dim_promo(promo_key),
    CONSTRAINT FK_fact_device    FOREIGN KEY (device_key)    REFERENCES gold.dim_device(device_key)
);
GO



/********************************************************************************************
 STORED PROCEDURE : gold.load_gold
 DESCRIPTION      : LOADS ALL GOLD LAYER TABLES IN CORRECT DEPENDENCY ORDER
                    DIMENSIONS FIRST, FACT TABLE LAST
********************************************************************************************/
CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    DECLARE
        @start_time       DATETIME,
        @end_time         DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time   DATETIME;

    BEGIN TRY
        SET NOCOUNT ON;

        SET @batch_start_time = GETDATE();

        PRINT 'Loading Gold Layer';
        PRINT '======================================================================';
        PRINT 'Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120);
        PRINT '';

        ------------------------------------------------------------
        -- STEP 1: DROP FK CONSTRAINTS BEFORE TRUNCATING
        ------------------------------------------------------------
        PRINT '>> Dropping FK Constraints';

        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_date')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_date;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_customer')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_customer;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_product')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_product;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_geography')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_geography;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_payment')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_payment;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_promo')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_promo;
        IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_fact_device')
            ALTER TABLE gold.fact_orders DROP CONSTRAINT FK_fact_device;

        PRINT '>> FK Constraints Dropped Successfully';
        PRINT '';

        ------------------------------------------------------------
        -- STEP 2: TRUNCATE ALL GOLD TABLES
        ------------------------------------------------------------
        PRINT '>> Truncating Gold Tables';

        TRUNCATE TABLE gold.fact_orders;
        TRUNCATE TABLE gold.dim_date;
        TRUNCATE TABLE gold.dim_customer;
        TRUNCATE TABLE gold.dim_product;
        TRUNCATE TABLE gold.dim_geography;
        TRUNCATE TABLE gold.dim_payment;
        TRUNCATE TABLE gold.dim_promo;
        TRUNCATE TABLE gold.dim_device;

        PRINT '>> All Tables Truncated Successfully';
        PRINT '';

        ------------------------------------------------------------
        -- DIM 1: dim_date
        ------------------------------------------------------------

        PRINT 'Processing: gold.dim_date';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();

        WITH date_spine AS (
            SELECT CAST('2022-12-31' AS DATE) AS dt
            UNION ALL
            SELECT DATEADD(DAY, 1, dt)
            FROM date_spine
            WHERE dt < '2024-12-31'
        ) 
        INSERT INTO gold.dim_date (
            date_key, full_date, day_of_week, day_number, week_number,
            month_number, month_name, quarter_number, quarter_name,
            year_number, is_weekend
        )
        SELECT
            CAST(FORMAT(dt, 'yyyyMMdd') AS INT)           AS date_key,
            dt                                             AS full_date,
            DATENAME(WEEKDAY, dt)                          AS day_of_week,
            DAY(dt)                                        AS day_number,
            DATEPART(WEEK, dt)                             AS week_number,
            MONTH(dt)                                      AS month_number,
            DATENAME(MONTH, dt)                            AS month_name,
            DATEPART(QUARTER, dt)                          AS quarter_number,
            'Q' + CAST(DATEPART(QUARTER, dt) AS NVARCHAR) AS quarter_name,
            YEAR(dt)                                       AS year_number,
            CASE
                WHEN DATENAME(WEEKDAY, dt) IN ('Saturday','Sunday') THEN 1
                ELSE 0
            END                                            AS is_weekend
        FROM date_spine
        OPTION (MAXRECURSION 1000);

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        ------------------------------------------------------------
        -- DIM 2: dim_customer
        ------------------------------------------------------------

        PRINT 'Processing: gold.dim_customer';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();

        WITH web_customers AS (
            SELECT DISTINCT
                customer_email,
                MAX(customer_name) AS customer_name
            FROM silver.website_orders
            WHERE customer_email IS NOT NULL
                AND customer_email != ''
            GROUP BY customer_email
        ),

        app_customers AS (
            SELECT DISTINCT user_email AS customer_email
            FROM silver.mobile_app_transactions
            WHERE user_email != 'Guest'
        ),
        all_customers AS (
            SELECT
                ISNULL(w.customer_email, a.customer_email) AS Customer_email,
                W.customer_name,
                CASE
                    WHEN w.customer_email IS NOT NULL
                     AND a.customer_email IS NOT NULL THEN 'Both'
                    WHEN w.customer_email IS NOT NULL THEN 'Website'
                    ELSE 'Mobile App'
                END AS preferred_channel,
                0 AS is_guest
            FROM web_customers w
            FULL OUTER JOIN app_customers a
                ON w.customer_email = a.customer_email

            UNION ALL
                SELECT 'Guest', 'Guest', 'Mobile App', 1
        )
        INSERT INTO gold.dim_customer (
            customer_email, customer_name, preferred_channel, is_guest
        )
        SELECT customer_email, customer_name, preferred_channel, is_guest
        FROM all_customers

        
        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        ------------------------------------------------------------
        -- DIM 3: dim_product
        ------------------------------------------------------------
                
        PRINT 'Processing: gold.dim_product';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();
        
        WITH web_products AS (
            SELECT DISTINCT
                product_id,
                MAX(product_name) AS product_name,
                MAX(category)     AS category
            FROM silver.website_orders
            GROUP BY product_id
        ),
        app_products AS (
            SELECT DISTINCT
                item_code             AS product_id,
                MAX(item_description) AS product_name,
                MAX(item_category)    AS category
            FROM silver.mobile_app_transactions
            GROUP BY item_code
        ),
        unified_products AS (
            SELECT
                ISNULL(w.product_id,   a.product_id)   AS product_id,
                ISNULL(w.product_name, a.product_name) AS product_name,
                ISNULL(w.category,     a.category)     AS category
            FROM web_products w
            FULL OUTER JOIN app_products a ON w.product_id = a.product_id
        )
        INSERT INTO gold.dim_product (product_id, product_name, category)
        SELECT product_id, product_name, category
        FROM unified_products;

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

         ------------------------------------------------------------
        -- DIM 4: dim_geography
        ------------------------------------------------------------
        PRINT 'Processing: gold.dim_geography';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();

        WITH all_geo AS (
            SELECT DISTINCT TRIM(country) AS country, TRIM(country) AS region
            FROM silver.website_orders
            WHERE country IS NOT NULL AND TRIM(country) != ''

            UNION

            SELECT DISTINCT TRIM(region), TRIM(region)
            FROM silver.mobile_app_transactions
            WHERE region IS NOT NULL AND TRIM(region) != ''

            UNION ALL
            SELECT 'N/A', 'N/A'
        )
        INSERT INTO gold.dim_geography (country, region)
        SELECT DISTINCT country, region
        FROM all_geo;

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

         ------------------------------------------------------------
        -- DIM 5: dim_payment
        ------------------------------------------------------------
        PRINT 'Processing: gold.dim_payment';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();

        WITH all_payments AS (
            SELECT DISTINCT TRIM(payment_method) AS payment_method
            FROM silver.website_orders
            WHERE payment_method IS NOT NULL AND TRIM(payment_method) != ''
            UNION
            SELECT DISTINCT TRIM(payment_type)
            FROM silver.mobile_app_transactions
            WHERE payment_type IS NOT NULL AND TRIM(payment_type) != ''
            UNION ALL
            SELECT 'N/A'
        )
        INSERT INTO gold.dim_payment (payment_method, payment_category)
        SELECT
            payment_method,
            CASE
                WHEN payment_method IN ('Apple Pay','Google Pay','In-App Wallet','PayPal')
                    THEN 'Digital Wallet'
                WHEN payment_method IN ('Credit Card','Debit Card','Card')
                    THEN 'Card'
                WHEN payment_method = 'N/A'
                    THEN 'N/A'
                ELSE 'Other'
            END
        FROM all_payments;

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        ------------------------------------------------------------
        -- DIM 6: dim_promo
        ------------------------------------------------------------
        PRINT 'Processing: gold.dim_promo';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();

        WITH all_promos AS (
            SELECT DISTINCT promo_code
            FROM silver.mobile_app_transactions
            WHERE promo_code IS NOT NULL AND TRIM(promo_code) != ''
            UNION ALL
            SELECT 'NO PROMO'
        )
        INSERT INTO gold.dim_promo (promo_code, discount_pct, promo_type)
        SELECT
            promo_code,
            CASE
                WHEN promo_code LIKE '%10%' THEN 10.00
                WHEN promo_code LIKE '%15%' THEN 15.00
                WHEN promo_code LIKE '%20%' THEN 20.00
                WHEN promo_code LIKE '%25%' THEN 25.00
                WHEN promo_code LIKE '%30%' THEN 30.00
                ELSE NULL
            END AS discount_pct,
            CASE
                WHEN promo_code LIKE 'SUMMER%'  THEN 'Seasonal'
                WHEN promo_code LIKE 'FLASH%'   THEN 'Flash'
                WHEN promo_code LIKE 'WELCOME%' THEN 'Welcome'
                WHEN promo_code LIKE 'VIP%'     THEN 'VIP'
                WHEN promo_code = 'NO PROMO'    THEN 'N/A'
                ELSE 'Other'
            END AS promo_type
        FROM all_promos;

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        ------------------------------------------------------------
        -- DIM 7: dim_device
        ------------------------------------------------------------
        PRINT 'Processing: gold.dim_device';
        PRINT '----------------------------------------------------------------------';
        SET @start_time = GETDATE();

        WITH all_devices AS (
            SELECT DISTINCT device_type, app_version
            FROM silver.mobile_app_transactions
            WHERE device_type IS NOT NULL AND device_type != 'Unknown'
            UNION ALL
            SELECT 'N/A', 'N/A'
        )
        INSERT INTO gold.dim_device (device_type, app_version)
        SELECT DISTINCT device_type, app_version
        FROM all_devices;

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

       -- ── WEBSITE ORDERS ─────

        INSERT INTO gold.fact_orders (
            date_key, customer_key, product_key, geography_key,
            payment_key, promo_key, device_key, order_id, channel,
            quantity, unit_price, discount, shipping_cost,
            total_amount, total_amount_usd, total_amount_recalc_usd,
            order_status, currency, is_negative_price, is_total_mismatch
        )    
        SELECT
            CAST(FORMAT(w.order_date, 'yyyyMMdd') AS INT),
            -- Foreign Keys of our DIM Tables
            c.customer_key,
            p.product_key,
            g.geography_key,
            pm.payment_key,
            pr.promo_key,
            dv.device_key,

            w.order_id,
            'Website',
            w.quantity,
            w.unit_price,
            w.discount,
            w.shipping_cost,
            w.total_amount,

            -- source total Coverted to USD
            ROUND( w.total_amount * CASE w.currency
                WHEN 'GBP' THEN  1.35
                WHEN 'EUR' THEN  0.85
                ELSE 1.00 END, 2),

            -- recalculated from components
            ROUND(
                (
                    ISNULL(w.quantity, 0)
                    * ISNULL(w.unit_price, 0)
                    - ISNULL(w.discount, 0)
                    + ISNULL(w.shipping_cost, 0)
                )
                * CASE w.currency
                    WHEN 'GBP' THEN 1.35
                    WHEN 'EUR' THEN 0.85
                    ELSE 1.00 END
            , 2),
            w.order_status,
            w.currency,
            w.is_negative_price,
            w.is_total_mismatch

        FROM Silver.website_orders w
        LEFT JOIN gold.dim_customer   c       ON w.customer_email          =  c.customer_email AND c.is_guest = 0
        LEFT JOIN gold.dim_product    p       ON w.product_id              =  p.product_id
        LEFT JOIN gold.dim_geography  g       ON TRIM(w.country)           =  g.country 
        LEFT JOIN gold.dim_payment   pm       ON TRIM(w.payment_method)    = pm.payment_method
        LEFT JOIN gold.dim_promo     pr       ON pr.promo_code             = 'NO PROMO'
        LEFT JOIN gold.dim_device    dv       ON dv.device_type            = 'N/A' AND dv.app_version = 'N/A'
        WHERE w.order_date IS NOT NULL;

        -- ── MOBILE APP TRANSACTIONS ─────
        INSERT INTO gold.fact_orders (
            date_key, customer_key, product_key, geography_key,
            payment_key, promo_key, device_key, order_id, channel,
            quantity, unit_price, discount, shipping_cost,
            total_amount, total_amount_usd, total_amount_recalc_usd,
            order_status, currency, is_negative_price, is_total_mismatch
        )
        SELECT
            CAST(FORMAT(CAST(m.transaction_timestamp AS DATE), 'yyyyMMdd') AS INT),
            CASE WHEN m.user_email = 'Guest' THEN gc.customer_key
                 ELSE c.customer_key END,
            p.product_key,
            g.geography_key,
            pm.payment_key,
            ISNULL(pr.promo_key, npr.promo_key),
            dv.device_key,
            m.transaction_id,
            'Mobile App',
            m.qty,
            m.price,
            NULL,
            m.delivery_fee,
            m.gross_total,

            -- source total converted to USD
            ROUND(m.gross_total * CASE m.currency_code
                WHEN 'GBP' THEN 1.35
                WHEN 'EUR' THEN 0.85
                ELSE 1.00 END, 2),

            -- recalculated from components
            -- note: discount not stored on app side
            -- variance between this and total_amount_usd = promo discount value
            ROUND(
                (
                    ISNULL(m.qty, 0)
                    * ISNULL(m.price, 0)
                    + ISNULL(m.delivery_fee, 0)
                )
                * CASE m.currency_code
                    WHEN 'GBP' THEN 1.35
                    WHEN 'EUR' THEN 0.85
                    ELSE 1.00 END
            , 2),

            m.delivery_status,
            m.currency_code,
            0,
            m.is_total_mismatch

        FROM silver.mobile_app_transactions m
        LEFT JOIN gold.dim_customer  c   ON m.user_email         = c.customer_email AND c.is_guest = 0
        LEFT JOIN gold.dim_customer  gc  ON gc.customer_email    = 'Guest'          AND gc.is_guest = 1
        LEFT JOIN gold.dim_product   p   ON m.item_code          = p.product_id
        LEFT JOIN gold.dim_geography g   ON TRIM(m.region)       = g.country
        LEFT JOIN gold.dim_payment   pm  ON TRIM(m.payment_type) = pm.payment_method
        LEFT JOIN gold.dim_promo     pr  ON m.promo_code         = pr.promo_code
                                        AND m.promo_code IS NOT NULL
                                        AND TRIM(m.promo_code)  != ''
        LEFT JOIN gold.dim_promo     npr ON npr.promo_code       = 'NO PROMO'
        LEFT JOIN gold.dim_device    dv  ON m.device_type        = dv.device_type
                                        AND m.app_version        = dv.app_version
        WHERE m.transaction_timestamp IS NOT NULL;

        SET @end_time = GETDATE();
        PRINT ' >> Rows Loaded : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT ' >> Duration    : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

         ------------------------------------------------------------
        -- STEP 3: RECREATE FK CONSTRAINTS AFTER LOADING
        ------------------------------------------------------------
        PRINT '>> Recreating FK Constraints';

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_date
            FOREIGN KEY (date_key) REFERENCES gold.dim_date(date_key);

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_customer
            FOREIGN KEY (customer_key) REFERENCES gold.dim_customer(customer_key);

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_product
            FOREIGN KEY (product_key) REFERENCES gold.dim_product(product_key);

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_geography
            FOREIGN KEY (geography_key) REFERENCES gold.dim_geography(geography_key);

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_payment
            FOREIGN KEY (payment_key) REFERENCES gold.dim_payment(payment_key);

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_promo
            FOREIGN KEY (promo_key) REFERENCES gold.dim_promo(promo_key);

        ALTER TABLE gold.fact_orders
            ADD CONSTRAINT FK_fact_device
            FOREIGN KEY (device_key) REFERENCES gold.dim_device(device_key);

        PRINT '>> FK Constraints Recreated Successfully';
        PRINT '';

        ------------------------------------------------------------
        -- BATCH END
        ------------------------------------------------------------
        SET @batch_end_time = GETDATE();

        PRINT '======================================================================';
        PRINT 'GOLD LAYER LOADED SUCCESSFULLY';
        PRINT 'Batch End Time  : ' + CONVERT(NVARCHAR, @batch_end_time, 120);
        PRINT 'Batch Duration  : '
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
              + ' seconds';
        PRINT '======================================================================';

    END TRY
    BEGIN CATCH
        PRINT '======================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING GOLD LAYER';
        PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR LINE    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '======================================================================';
        THROW;
    END CATCH
END;
GO

EXEC gold.load_gold
