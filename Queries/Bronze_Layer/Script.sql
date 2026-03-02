/********************************************************************************************
 SCRIPT NAME : BRONZE LAYER DDL & LOAD
 DESCRIPTION :
     CREATES BRONZE LAYER TABLES FOR WEBSITE AND MOBILE APP SOURCE DATA
     AND LOADS DATA USING BULK INSERT.
********************************************************************************************/
/********************************************************************************************
 SCRIPT NAME : BRONZE LAYER DDL & LOAD
 DESCRIPTION :
     CREATES BRONZE LAYER TABLES FOR WEBSITE AND MOBILE APP SOURCE DATA
     AND LOADS DATA USING BULK INSERT.
********************************************************************************************/

------------------------------------------------------------
-- WEBSITE ORDERS TABLE
------------------------------------------------------------

IF OBJECT_ID ('bronze.website_orders', 'U') IS NOT NULL
    DROP TABLE bronze.website_orders;

CREATE TABLE bronze.website_orders (
    order_id          NVARCHAR(50),
    order_date        NVARCHAR(50),
    customer_email    NVARCHAR(100),
    customer_name     NVARCHAR(100),
    product_id        NVARCHAR(50),
    product_name      NVARCHAR(100),
    category          NVARCHAR(50),
    quantity          NVARCHAR(50),
    unit_price        NVARCHAR(50),
    total_amount      NVARCHAR(50),
    discount          NVARCHAR(50),
    shipping_cost     NVARCHAR(50),
    order_status      NVARCHAR(50),
    payment_method    NVARCHAR(50),
    shipping_address  NVARCHAR(255),
    country           NVARCHAR(50),
    currency          NVARCHAR(10)
);


------------------------------------------------------------
-- MOBILE APP TRANSACTIONS TABLE
------------------------------------------------------------

IF OBJECT_ID('bronze.mobile_app_transactions', 'U') IS NOT NULL
    DROP TABLE bronze.mobile_app_transactions;

CREATE TABLE bronze.mobile_app_transactions (
    transaction_id        NVARCHAR(50),
    transaction_timestamp NVARCHAR(50),
    user_id               NVARCHAR(50),
    user_email            NVARCHAR(100),
    item_code             NVARCHAR(50),
    item_description      NVARCHAR(100),
    item_category         NVARCHAR(50),
    qty                   NVARCHAR(50),
    price                 NVARCHAR(50),
    gross_total           NVARCHAR(50),
    promo_code            NVARCHAR(50),
    delivery_fee          NVARCHAR(50),
    delivery_status       NVARCHAR(50),
    payment_type          NVARCHAR(50),
    device_type           NVARCHAR(50),
    app_version           NVARCHAR(20),
    region                NVARCHAR(50),
    currency_code         NVARCHAR(10)
);


------------------------------------------------------------
-- STORED PROCEDURE: bronze.load_bronze
------------------------------------------------------------


CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    DECLARE
        @start_time       DATETIME,
        @end_time         DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time   DATETIME;

    BEGIN TRY
        SET NOCOUNT ON;

    -- Batch start
    SET @batch_start_time = GETDATE();

    PRINT 'Loading Bronze Layer';
    PRINT '======================================================================';
    PRINT 'Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120);
    PRINT '';

    ------------------------------------------------------------
    -- WEBSITE ORDERS
    ------------------------------------------------------------

    PRINT 'Loading Website Source Tables';
    PRINT '----------------------------------------------------------------------';

    -- website_orders
    SET @start_time = GETDATE();

    PRINT '>> Truncating Table: bronze.website_orders';
    TRUNCATE TABLE bronze.website_orders;

    PRINT '>> Inserting Data Into: bronze.website_orders';
    SET NOCOUNT OFF;

    BULK INSERT bronze.website_orders
    FROM 'G:\My Drive\Cohort 7\SQL for Data Analytics\Projects\website_orders.csv'
    WITH (
        FIRSTROW           = 2,
        FIELDTERMINATOR    = ',',
        ROWTERMINATOR      = '\n',
        TABLOCK
    );

    SET NOCOUNT ON;
    SET @end_time = GETDATE();

    PRINT ' >> Load Duration: '
           + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
           + ' seconds';
    PRINT ' >> -------------------------------------------------';
    PRINT '';

    PRINT 'WEBSITE TABLES LOADED SUCCESSFULLY';
    PRINT '----------------------------------------------------------------------';


    ------------------------------------------------------------
    -- MOBILE APP TRANSACTIONS
    ------------------------------------------------------------

    PRINT 'Loading Mobile App Source Tables';
    PRINT '----------------------------------------------------------------------';

    -- mobile_app_transactions
    SET @start_time = GETDATE();

    PRINT '>> Truncating Table: bronze.mobile_app_transactions';
    TRUNCATE TABLE bronze.mobile_app_transactions;

    PRINT '>> Inserting Data Into: bronze.mobile_app_transactions';
    SET NOCOUNT OFF;

    BULK INSERT bronze.mobile_app_transactions
    FROM 'G:\My Drive\Cohort 7\SQL for Data Analytics\Projects\mobile_app_transactions.csv'
    WITH (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '\n',
        TABLOCK
    );

    SET NOCOUNT ON;
    SET @end_time = GETDATE();

    PRINT ' >> Load Duration: '
          + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
          + ' seconds';
    PRINT ' >> -------------------------------------------------';
    PRINT '';

    PRINT 'MOBILE APP TABLES LOADED SUCCESSFULLY';
    PRINT '----------------------------------------------------------------------';

    ------------------------------------------------------------
    -- VALIDATION: ROW COUNT CHECK
    ------------------------------------------------------------

    PRINT 'Validating Row Counts...';
    PRINT '----------------------------------------------------------------------';

    DECLARE @web_rows INT,
            @app_rows INT;

    SELECT @web_rows = COUNT(*)
    FROM bronze.website_orders;

    SELECT @app_rows = COUNT(*)
    FROM bronze.mobile_app_transactions;

    PRINT 'Website Rows Loaded: ' + CAST(@web_rows AS NVARCHAR);
    PRINT 'App Rows Loaded    : ' + CAST(@app_rows AS NVARCHAR);

    PRINT '----------------------------------------------------------------------';
    PRINT '';

    ------------------------------------------------------------
    -- BATCH END
    ------------------------------------------------------------

    SET @batch_end_time = GETDATE();
    
    PRINT '======================================================================';
    PRINT 'BRONZE LAYER LOADED SUCCESSFULLY';
    PRINT 'Batch End Time  : ' + CONVERT(NVARCHAR, @batch_end_time, 120);
    PRINT 'Total Duration  : '
          + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
          + ' seconds';
    PRINT '======================================================================';
END TRY

    BEGIN CATCH
        PRINT '======================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR LINE    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '======================================================================';

        THROW;
    END CATCH
END;

EXEC bronze.load_bronze
