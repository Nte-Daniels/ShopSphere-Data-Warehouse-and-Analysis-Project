/********************************************************************************************
 SCRIPT NAME : SILVER LAYER — FULL DDL & TRANSFORMATION LOAD 
 SOURCE      : bronze.website_orders
 TARGET      : silver.website_orders
 DESCRIPTION :
     CREATES THE SILVER TABLE AND STORED PROCEDURE TO CLEAN,
     STANDARDIZE, AND LOAD WEBSITE ORDERS FROM THE BRONZE LAYER.
********************************************************************************************/

------------------------------------------------------------
-- SILVER TABLE DDL
------------------------------------------------------------

------------------------------------------------------------
-- TABLE 1: silver.website_orders DDL
------------------------------------------------------------
IF OBJECT_ID('silver.website_orders', 'U') IS NOT NULL
    DROP TABLE silver.website_orders;
GO

CREATE TABLE silver.website_orders (
    silver_id             INT IDENTITY(1,1)   NOT NULL,
    order_id              NVARCHAR(20)        NOT NULL,
    order_date            DATE                NULL,
    order_date_raw        NVARCHAR(50)        NULL,
    customer_email        NVARCHAR(255)       NULL,
    customer_name         NVARCHAR(255)       NULL,
    product_id            NVARCHAR(20)        NULL,
    product_name          NVARCHAR(255)       NULL,
    category              NVARCHAR(100)       NULL,
    quantity              INT                 NULL,
    unit_price            DECIMAL(10,2)       NULL,
    discount              DECIMAL(10,2)       NULL,
    shipping_cost         DECIMAL(10,2)       NULL,
    total_amount          DECIMAL(10,2)       NULL,
    is_negative_price     BIT                 NOT NULL DEFAULT 0,
    is_total_mismatch     BIT                 NOT NULL DEFAULT 0,
    order_status          NVARCHAR(50)        NULL,
    payment_method        NVARCHAR(100)       NULL,
    shipping_address      NVARCHAR(500)       NULL,
    country               NVARCHAR(100)       NULL,
    currency              NVARCHAR(10)        NULL,
    dwh_load_timestamp    DATETIME            NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_silver_website_orders PRIMARY KEY (silver_id)
);
GO


------------------------------------------------------------
-- TABLE 2: silver.mobile_app_transactions DDL
------------------------------------------------------------
IF OBJECT_ID('silver.mobile_app_transactions', 'U') IS NOT NULL
    DROP TABLE silver.mobile_app_transactions;
GO

CREATE TABLE silver.mobile_app_transactions (
    silver_id                  INT IDENTITY(1,1)   NOT NULL,
    transaction_id             NVARCHAR(50)        NOT NULL,
    transaction_timestamp      DATETIME            NULL,
    transaction_timestamp_raw  NVARCHAR(50)        NULL,
    user_id                    NVARCHAR(50)        NULL,
    user_email                 NVARCHAR(255)       NULL,
    item_code                  NVARCHAR(20)        NULL,
    item_description           NVARCHAR(255)       NULL,
    item_category              NVARCHAR(100)       NULL,
    qty                        INT                 NULL,
    price                      DECIMAL(10,2)       NULL,
    delivery_fee               DECIMAL(10,2)       NULL,
    gross_total                DECIMAL(10,2)       NULL,
    is_total_mismatch          BIT                 NOT NULL DEFAULT 0,
    promo_code                 NVARCHAR(50)        NULL,
    delivery_status            NVARCHAR(50)        NULL,
    payment_type               NVARCHAR(100)       NULL,
    device_type                NVARCHAR(20)        NULL,
    app_version                NVARCHAR(20)        NULL,
    region                     NVARCHAR(100)       NULL,
    currency_code              NVARCHAR(10)        NULL,
    dwh_load_timestamp         DATETIME            NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_silver_mobile_app_transactions PRIMARY KEY (silver_id)
);
GO



------------------------------------------------------------
-- PROCEDURE 1: silver.load_silver_website_orders
------------------------------------------------------------


CREATE OR ALTER PROCEDURE silver.load_silver_website_orders
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

        PRINT 'Loading Silver Layer';
        PRINT '======================================================================';
        PRINT 'Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120);
        PRINT '';

        PRINT 'Processing: silver.website_orders';
        PRINT '----------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.website_orders';
        TRUNCATE TABLE silver.website_orders;

        PRINT '>> Inserting Data Into: silver.website_orders';
        SET NOCOUNT OFF;

        -- CTE 1: All Transformations for the Website Data

        ;WITH normalized AS
         (   
            SELECT
                b.order_id,

                -- Date Normalization
                TRY_CAST(
                    CASE
                        WHEN b.order_date LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
                            THEN b.order_date
                        WHEN b.order_date LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'
                            THEN SUBSTRING(b.order_date,7,4)+'-'
                               + SUBSTRING(b.order_date,1,2)+'-'
                               + SUBSTRING(b.order_date,4,2)
                        WHEN b.order_date LIKE '[0-9][0-9]-[A-Z][a-z][a-z]-[0-9][0-9][0-9][0-9]'
                            THEN CONVERT(NVARCHAR(10), CONVERT(DATE, b.order_date, 106), 23)
                        WHEN b.order_date LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9][0-9][0-9]'
                            THEN SUBSTRING(b.order_date,7,4)+'-'
                               + SUBSTRING(b.order_date,4,2)+'-'
                               + SUBSTRING(b.order_date,1,2)
                        WHEN b.order_date LIKE '[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]'
                            THEN REPLACE(b.order_date,'/','-')
                        ELSE NULL
                    END
                AS DATE)                                               AS order_date,

                b.order_date                                           AS order_date_raw,
                
                -- Customers--
                LOWER(TRIM(b.customer_email))                          AS customer_email,
                ISNULL(NULLIF(TRIM(b.customer_name),''), 'Unknown')    AS customer_name,

                -- Product ID: all 7 Variants  PROD-NNN --

                'PROD-' + RIGHT ('000' +
                    CASE
                        WHEN b.product_id LIKE '%-%'
                            THEN SUBSTRING(b.product_id,
                                     CHARINDEX('-', b.product_id) +1,
                                     LEN(b.product_id))
                        WHEN UPPER(b.product_id) LIKE 'PROD[0-9]%'
                            THEN SUBSTRING(b.product_id, 5, LEN(b.product_id))
                        WHEN b.product_id LIKE 'P[0-9]%'
                            THEN SUBSTRING(b.product_id, 2, LEN(b.product_id))
                        ELSE b.product_id
                    END 
                , 3)                                                  AS product_id_normalized,
                
                TRIM(b.product_name)                                  AS product_name,
                TRIM(b.category)                                      AS category,

                -- NUMERICS
                TRY_CAST(b.quantity AS INT)                            AS quantity,
                TRY_CAST(b.unit_price AS DECIMAL(10,2))                AS unit_price,
                ISNULL(TRY_CAST(b.discount AS DECIMAL(10,2)), 0.00)    AS discount,
                ISNULL(TRY_CAST(b.shipping_cost AS DECIMAL(10,2)),0.00)AS shipping_cost,
                TRY_CAST(b.total_amount AS DECIMAL(10,2))              AS total_amount,

                -- FLAGS

                CASE
                    WHEN TRY_CAST(b.unit_price AS DECIMAL(10,2)) < 0 THEN 1
                    ELSE 0                                            
                END                                                    AS is_negative_price,

                CASE
                    WHEN ABS(
                        ISNULL(TRY_CAST(b.total_amount AS DECIMAL(10,2)), 0)
                        - (
                            ISNULL(TRY_CAST(b.quantity AS INT), 0)
                            * ISNULL(TRY_CAST(b.unit_price AS DECIMAL(10,2)), 0)
                            - ISNULL(TRY_CAST(b.discount AS DECIMAL(10,2)), 0)
                            + ISNULL(TRY_CAST(b.shipping_cost AS DECIMAL(10,2)), 0)
                        )
                    ) > 0.01 THEN 1
                    ELSE 0
                END                                                     AS is_total_mismatch,

                -- ORDER STATUS
                CASE UPPER(TRIM(b.order_status))
                    WHEN 'COMPLETED'         THEN 'Completed'
                    WHEN 'COMPLETE'          THEN 'Completed'
                    WHEN 'SUCCESS'           THEN 'Completed'
                    WHEN 'DISPATCHED'        THEN 'Shipped'
                    WHEN 'IN PROGRESS'       THEN 'Shipped'
                    WHEN 'PENDING'           THEN 'Pending'
                    WHEN 'CANCELLED'         THEN 'Cancelled'
                    WHEN 'CANCELED'          THEN 'Cancelled'
                    WHEN 'DELIVERED'         THEN 'Delivered'
                    WHEN 'RETURNED'          THEN 'Returned'
                    ELSE 'Unknown'
                END                                                         AS  order_status,
                
                TRIM(b.payment_method)                                      AS payment_method,
                ISNULL(NULLIF(TRIM(b.shipping_address),''), 'Not Provided') AS shipping_address,
                TRIM(b.country)                                             AS Country,

                -- Currency
                CASE    
                    WHEN UPPER(TRIM(b.currency)) IN ('USD', '$') THEN 'USD'

                    WHEN UPPER(TRIM(b.currency)) LIKE '%P%'
                         OR UPPER(TRIM(b.currency)) LIKE '%£%'
                         OR UPPER(TRIM(b.currency)) LIKE '%GB%'
                    THEN 'GBP'
                    
                    WHEN UPPER(TRIM(b.currency)) LIKE '%EUR%'
                         OR UPPER(TRIM(b.currency)) LIKE '%€%'
                         OR UPPER(TRIM(b.currency)) LIKE '%Ô%'
                    THEN 'EUR'

                    WHEN b.currency IS NULL 
                        OR TRIM(b.currency) = ''
                    THEN 'Unknown'

                    ELSE 'Unknown'
                END                                                           AS Currency
            FROM bronze.website_orders b
            WHERE b.order_id IS NOT NULL
        ),
            -- CTE 2: Dedup After Normalisation
        deduped AS
        (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY order_id, product_id_normalized
                    ORDER BY order_id
                    ) AS rn
            FROM normalized
        )

            INSERT INTO silver.website_orders (
            order_id,
            order_date,
            order_date_raw,
            customer_email,
            customer_name,
            product_id,
            product_name,
            category,
            quantity,
            unit_price,
            discount,
            shipping_cost,
            total_amount,
            is_negative_price,
            is_total_mismatch,
            order_status,
            payment_method,
            shipping_address,
            country,
            currency
        )
        SELECT
            order_id,
            order_date,
            order_date_raw,
            customer_email,
            customer_name,
            product_id_normalized,
            product_name,
            category,
            quantity,
            unit_price,
            discount,
            shipping_cost,
            total_amount,
            is_negative_price,
            is_total_mismatch,
            order_status,
            payment_method,
            shipping_address,
            country,
            currency
        FROM deduped
        WHERE rn = 1;

        SET NOCOUNT ON;
        SET @end_time = GETDATE();

        PRINT ' >> Load Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';
        PRINT ' >> -------------------------------------------------';
        PRINT '';

        SET @batch_end_time = GETDATE();

        PRINT '======================================================================';
        PRINT 'SILVER LAYER LOADED SUCCESSFULLY';
        PRINT 'Batch End Time  : ' + CONVERT(NVARCHAR, @batch_end_time, 120);
        PRINT 'Total Duration  : '
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
              + ' seconds';
        PRINT '======================================================================';

    END TRY
    BEGIN CATCH
        PRINT '======================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR LINE    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '======================================================================';
        THROW;
    END CATCH
END;
GO

 

------------------------------------------------------------
-- PROCEDURE 2: silver.load_silver_mobile_app_transactions
------------------------------------------------------------
CREATE OR ALTER PROCEDURE silver.load_silver_mobile_app_transactions
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

        PRINT 'Loading Silver Layer';
        PRINT '======================================================================';
        PRINT 'Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120);
        PRINT '';

        PRINT 'Processing: silver.mobile_app_transactions';
        PRINT '----------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.mobile_app_transactions';
        TRUNCATE TABLE silver.mobile_app_transactions;

        PRINT '>> Inserting Data Into: silver.mobile_app_transactions';
        SET NOCOUNT OFF;

        -- -- CTE 1: all transformations --------------------------------
        ;WITH normalized AS
        (
            SELECT
                b.transaction_id,

                /* TIMESTAMP: 3 formats ? DATETIME */
                CASE
                    WHEN b.transaction_timestamp LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T%'
                        THEN TRY_CAST(
                                REPLACE(b.transaction_timestamp,'T',' ')
                             AS DATETIME)
                    WHEN b.transaction_timestamp LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] %'
                        THEN TRY_CAST(b.transaction_timestamp AS DATETIME)
                    WHEN TRY_CAST(b.transaction_timestamp AS BIGINT) IS NOT NULL
                        THEN DATEADD(
                                SECOND,
                                TRY_CAST(b.transaction_timestamp AS BIGINT),
                                '1970-01-01 00:00:00'
                             )
                    ELSE NULL
                END                                                     AS transaction_timestamp,

                b.transaction_timestamp                                 AS transaction_timestamp_raw,

                b.user_id,

                /* USER EMAIL */
                ISNULL(LOWER(TRIM(b.user_email)), 'Guest')              AS user_email,

                /* ITEM CODE: all variants ? PROD-NNN */
                'PROD-' + RIGHT('000' +
                    CASE
                        WHEN b.item_code LIKE 'MOB-PROD-%'
                            THEN SUBSTRING(b.item_code,
                                    LEN('MOB-PROD-')+1,
                                    LEN(b.item_code))
                        WHEN b.item_code LIKE 'APP-[0-9]%'
                            THEN SUBSTRING(b.item_code,
                                    CHARINDEX('-', b.item_code)+1,
                                    LEN(b.item_code))
                        WHEN b.item_code LIKE 'APP[_][0-9]%'
                            THEN SUBSTRING(b.item_code,
                                    CHARINDEX('_', b.item_code)+1,
                                    LEN(b.item_code))
                        WHEN b.item_code LIKE 'M[0-9]%'
                            THEN SUBSTRING(b.item_code, 2, LEN(b.item_code))
                        WHEN b.item_code LIKE 'PROD-[0-9]%'
                            THEN SUBSTRING(b.item_code,
                                    CHARINDEX('-', b.item_code)+1,
                                    LEN(b.item_code))
                        WHEN b.item_code LIKE 'PROD[0-9]%'
                            THEN SUBSTRING(b.item_code, 5, LEN(b.item_code))
                        ELSE b.item_code
                    END
                , 3)                                                    AS item_code_normalized,

                TRIM(b.item_description)                                AS item_description,

                /* ITEM CATEGORY: 23 variants ? 6 canonical */
                CASE UPPER(TRIM(b.item_category))
                    WHEN 'TECH'          THEN 'Electronics'
                    WHEN 'TECHNOLOGY'    THEN 'Electronics'
                    WHEN 'ELECTR.'       THEN 'Electronics'
                    WHEN 'ELECTRONICS'   THEN 'Electronics'
                    WHEN 'APPAREL'       THEN 'Fashion'
                    WHEN 'CLOTHING'      THEN 'Fashion'
                    WHEN 'FASHION'       THEN 'Fashion'
                    WHEN 'HOME'          THEN 'Home & Kitchen'
                    WHEN 'H&K'           THEN 'Home & Kitchen'
                    WHEN 'KITCHEN'       THEN 'Home & Kitchen'
                    WHEN 'HOME & KITCHEN' THEN 'Home & Kitchen'
                    WHEN 'SPORTS'        THEN 'Sports'
                    WHEN 'SPORT'         THEN 'Sports'
                    WHEN 'FITNESS'       THEN 'Sports'
                    WHEN 'OUTDOORS'      THEN 'Sports'
                    WHEN 'BOOKS'         THEN 'Books'
                    WHEN 'MEDIA'         THEN 'Books'
                    WHEN 'LIT'           THEN 'Books'
                    WHEN 'READING'       THEN 'Books'
                    WHEN 'BEAUTY'        THEN 'Beauty'
                    WHEN 'PERSONAL_CARE' THEN 'Beauty'
                    WHEN 'PERSONAL CARE' THEN 'Beauty'
                    WHEN 'COSMETICS'     THEN 'Beauty'
                    ELSE 'Unknown'
                END                                                     AS item_category,

                /* NUMERICS */
                TRY_CAST(b.qty AS INT)                                  AS qty,
                TRY_CAST(b.price AS DECIMAL(10,2))                      AS price,
                ISNULL(TRY_CAST(b.delivery_fee AS DECIMAL(10,2)),0.00)  AS delivery_fee,
                TRY_CAST(b.gross_total AS DECIMAL(10,2))                AS gross_total,

                /* FLAG: TOTAL MISMATCH */
                CASE
                    WHEN ABS(
                        ISNULL(TRY_CAST(b.gross_total AS DECIMAL(10,2)), 0)
                        - (
                            ISNULL(TRY_CAST(b.qty AS INT), 0)
                            * ISNULL(TRY_CAST(b.price AS DECIMAL(10,2)), 0)
                            + ISNULL(TRY_CAST(b.delivery_fee AS DECIMAL(10,2)), 0)
                        )
                    ) > 0.01 THEN 1
                    ELSE 0
                END                                                     AS is_total_mismatch,

                /* PROMO CODE: uppercase + strip special chars */
                REPLACE(
                    REPLACE(
                        REPLACE(
                            UPPER(TRIM(b.promo_code))
                        ,'-','')
                    ,'_','')
                ,'%','')                                                AS promo_code,

                /* DELIVERY STATUS: 6 encoded ? 5 canonical */
                CASE UPPER(TRIM(b.delivery_status))
                    WHEN 'DLV'  THEN 'Delivered'
                    WHEN 'SHIP' THEN 'Shipped'
                    WHEN 'PEND' THEN 'Pending'
                    WHEN 'PROC' THEN 'Pending'
                    WHEN 'CANC' THEN 'Cancelled'
                    WHEN 'RET'  THEN 'Returned'
                    ELSE 'Unknown'
                END                                                     AS delivery_status,

                TRIM(b.payment_type)                                    AS payment_type,

                /* DEVICE TYPE: 4 variants ? 2 canonical */
                CASE UPPER(TRIM(b.device_type))
                    WHEN 'ANDROID' THEN 'Android'
                    WHEN 'IOS'     THEN 'iOS'
                    WHEN 'IPHONE'  THEN 'iOS'
                    WHEN 'IPAD'    THEN 'iOS'
                    ELSE 'Unknown'
                END                                                     AS device_type,

                TRIM(b.app_version)                                     AS app_version,
                TRIM(b.region)                                          AS region,

                /* currency_code */
                CASE
                    WHEN UPPER(TRIM(b.currency_code)) IN ('USD', '$') THEN 'USD'

                    WHEN UPPER(TRIM(b.currency_code)) LIKE '%P%'
                         OR UPPER(TRIM(b.currency_code)) LIKE '%£%'
                         OR UPPER(TRIM(b.currency_code)) LIKE '%GB%'
                    THEN 'GBP'

                    WHEN UPPER(TRIM(b.currency_code)) LIKE '%EUR%'
                         OR UPPER(TRIM(b.currency_code)) LIKE '%€%'
                         OR UPPER(TRIM(b.currency_code)) LIKE '%Ô%'
                    THEN 'EUR'

                    WHEN b.currency_code IS NULL
                         OR TRIM(b.currency_code) = ''
                    THEN 'Unknown'

                    ELSE 'Unknown'
                END                                                   AS currency_code

            FROM bronze.mobile_app_transactions b
            WHERE b.transaction_id IS NOT NULL
        ),

        -- -- CTE 2: dedup after normalisation -------------------------
        deduped AS
        (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY transaction_id
                       ORDER BY transaction_id
                   ) AS rn
            FROM normalized
        )

        INSERT INTO silver.mobile_app_transactions (
            transaction_id,
            transaction_timestamp,
            transaction_timestamp_raw,
            user_id,
            user_email,
            item_code,
            item_description,
            item_category,
            qty,
            price,
            delivery_fee,
            gross_total,
            is_total_mismatch,
            promo_code,
            delivery_status,
            payment_type,
            device_type,
            app_version,
            region,
            currency_code
        )
        SELECT
            transaction_id,
            transaction_timestamp,
            transaction_timestamp_raw,
            user_id,
            user_email,
            item_code_normalized,
            item_description,
            item_category,
            qty,
            price,
            delivery_fee,
            gross_total,
            is_total_mismatch,
            promo_code,
            delivery_status,
            payment_type,
            device_type,
            app_version,
            region,
            currency_code
        FROM deduped
        WHERE rn = 1;

        SET NOCOUNT ON;
        SET @end_time = GETDATE();

        PRINT ' >> Load Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';
        PRINT ' >> -------------------------------------------------';
        PRINT '';

        SET @batch_end_time = GETDATE();

        PRINT '======================================================================';
        PRINT 'SILVER LAYER LOADED SUCCESSFULLY';
        PRINT 'Batch End Time  : ' + CONVERT(NVARCHAR, @batch_end_time, 120);
        PRINT 'Total Duration  : '
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
              + ' seconds';
        PRINT '======================================================================';

    END TRY
    BEGIN CATCH
        PRINT '======================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR LINE    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '======================================================================';
        THROW;
    END CATCH
END;
GO


------------------------------------------------------------
-- EXECUTE BOTH
------------------------------------------------------------
EXEC silver.load_silver_website_orders;
GO
EXEC silver.load_silver_mobile_app_transactions;
GO
