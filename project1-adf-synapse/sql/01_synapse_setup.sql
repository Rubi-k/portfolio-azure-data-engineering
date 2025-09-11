-- ===========================================
-- Synapse Serverless Setup Script
-- Project: demo_portfolio
-- ===========================================

-- 1) Create a logical database
CREATE DATABASE demo_portfolio;
GO

-- 2) Switch context to this database
USE demo_portfolio;
GO

-- 3) Create a Master Key (only once per database)
-- IMPORTANT: Use a strong password. Do NOT commit this password to GitHub.
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Your_Strong_Password_2025!';
GO

-- 4) Create a database scoped credential with SAS
-- Replace <SAS_TOKEN> with your actual SAS token (include the leading "?").
-- Never upload the real SAS token to GitHub – use a placeholder instead.
CREATE DATABASE SCOPED CREDENTIAL blob_curated_sas
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = '?<SAS_TOKEN>';
GO

-- 5) Create the External Data Source (only if it does not exist)
IF NOT EXISTS (
    SELECT * FROM sys.external_data_sources WHERE name = 'eds_blob_curated'
)
BEGIN
    CREATE EXTERNAL DATA SOURCE eds_blob_curated
    WITH (
        LOCATION   = 'https://stdataengdemo2025.blob.core.windows.net/curated',
        CREDENTIAL = blob_curated_sas
    );
END
GO

-- 6) Test query: read from curated/customers (Parquet)
SELECT TOP 10 *
FROM OPENROWSET(
    BULK 'customers/',
    DATA_SOURCE = 'eds_blob_curated',
    FORMAT = 'PARQUET'
) AS r;
GO

-- 7) Test query: read from curated/orders (Parquet)
SELECT TOP 10 *
FROM OPENROWSET(
    BULK 'orders/',
    DATA_SOURCE = 'eds_blob_curated',
    FORMAT = 'PARQUET'
) AS r;
GO
