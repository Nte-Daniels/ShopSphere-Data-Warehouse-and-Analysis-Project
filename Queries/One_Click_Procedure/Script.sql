CREATE OR ALTER PROCEDURE run_full_pipeline
AS
BEGIN
    DECLARE
        @pipeline_start_time DATETIME,
        @pipeline_end_time   DATETIME;

    BEGIN TRY
        SET NOCOUNT ON;

        SET @pipeline_start_time = GETDATE();

        PRINT '==============================================================';
        PRINT 'FULL DATA PIPELINE STARTED';
        PRINT 'Start Time: ' + CONVERT(NVARCHAR, @pipeline_start_time, 120);
        PRINT '==============================================================';
        PRINT '';

        ------------------------------------------------------------
        -- STEP 0: LOAD BRONZE (BULK INSERT)
        ------------------------------------------------------------
        PRINT 'Step 0: Loading Bronze Layer';
        EXEC bronze.load_bronze;
        PRINT 'Step 0 Completed';
        PRINT '';

        ------------------------------------------------------------
        -- STEP 1: LOAD SILVER
        ------------------------------------------------------------
        PRINT 'Step 1: Loading Silver Layer';
        EXEC silver.load_silver_website_orders;
        EXEC silver.load_silver_mobile_app_transactions;
        PRINT 'Step 1 Completed';
        PRINT '';

        ------------------------------------------------------------
        -- STEP 2: LOAD GOLD
        ------------------------------------------------------------
        PRINT 'Step 2: Loading Gold Layer';
        EXEC gold.load_gold;
        PRINT 'Step 2 Completed';
        PRINT '';

        ------------------------------------------------------------
        -- PIPELINE END
        ------------------------------------------------------------
        SET @pipeline_end_time = GETDATE();

        PRINT '==============================================================';
        PRINT 'FULL DATA PIPELINE COMPLETED SUCCESSFULLY';
        PRINT 'End Time   : ' + CONVERT(NVARCHAR, @pipeline_end_time, 120);
        PRINT 'Total Time : '
              + CAST(DATEDIFF(SECOND, @pipeline_start_time, @pipeline_end_time) AS NVARCHAR)
              + ' seconds';
        PRINT '==============================================================';

    END TRY
    BEGIN CATCH
        PRINT '==============================================================';
        PRINT 'PIPELINE FAILED';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '==============================================================';
        THROW;
    END CATCH
END;
GO

EXEC run_full_pipeline
