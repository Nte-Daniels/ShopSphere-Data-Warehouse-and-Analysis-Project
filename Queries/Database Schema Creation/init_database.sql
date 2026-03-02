/********************************************************************************************
 Script Name : Create Database and Schemas
 Author      : Nte Daniel Daniel
 Created On  : 2026-02-21
 Description :
     Creates a new database named 'ShopSphereDW' after checking if it already exists.
     If the database exists, it is dropped and recreated. The script also initializes
     three schemas within the database to support a Medallion Architecture:
         - bronze  : Raw ingestion layer — data loaded as-is from source CSV files
         - silver  : Cleaned and standardised layer — quality issues resolved
         - gold    : Analytical data mart — star schema ready for reporting
 Source Data :
     - website_orders.csv          (50,000 rows — Web channel)
     - mobile_app_transactions.csv (27,000 rows — Mobile channel)
 WARNING :
     Executing this script will DROP the entire 'ShopSphereDW' database if it exists.
     All existing data will be permanently deleted.
     Proceed with caution and ensure proper backups are taken before execution.
********************************************************************************************/


USE master;


-- DROP and recreate the 'ShopSphereDW' Database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ShopSphereDW')
BEGIN
    ALTER DATABASE ShopSphereDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ShopSphereDW;
END;
GO

-- Create the 'ShopSphereDW' Database

CREATE DATABASE ShopSphereDW;
GO

USE ShopSphereDW;
GO

-- Create Medallion Architecture Schemas

CREATE SCHEMA bronze;        -- Raw ingestion: no transformations permitted
GO
CREATE SCHEMA silver;        -- Cleaned data: standardised, deduplicated, validated
GO
CREATE SCHEMA gold;           -- Analytical mart: star schema for reporting and insights
GO
