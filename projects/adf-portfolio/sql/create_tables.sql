-- create_tables.sql
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.dim_currency_rate') AND type='U')
BEGIN
  CREATE TABLE dbo.dim_currency_rate(
    rate_date      DATE          NOT NULL,
    src_currency   CHAR(3)       NOT NULL,
    dst_currency   CHAR(3)       NOT NULL,
    rate           DECIMAL(18,8) NOT NULL,
    CONSTRAINT PK_dim_currency_rate PRIMARY KEY (rate_date, src_currency, dst_currency)
  );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.stg_sales') AND type='U')
BEGIN
  CREATE TABLE dbo.stg_sales(
    sale_id       BIGINT        NOT NULL PRIMARY KEY,
    product_id    INT           NOT NULL,
    sale_ts       DATETIME2     NOT NULL,
    qty           INT           NOT NULL,
    amount_src    DECIMAL(18,2) NOT NULL,
    currency_src  CHAR(3)       NOT NULL
  );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.fact_sales') AND type='U')
BEGIN
  CREATE TABLE dbo.fact_sales(
    sale_id       BIGINT        NOT NULL PRIMARY KEY,
    product_id    INT           NOT NULL,
    sale_ts       DATETIME2     NOT NULL,
    qty           INT           NOT NULL,
    amount_src    DECIMAL(18,2) NOT NULL,
    currency_src  CHAR(3)       NOT NULL,
    amount_usd    DECIMAL(18,2) NULL
  );
END;
GO
