-- sp_load_rates.sql
CREATE OR ALTER PROCEDURE dbo.sp_load_rates
  @proc_date  DATE,
  @payload    NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @rate_date DATE = TRY_CONVERT(DATE, JSON_VALUE(@payload, '$.date'));
  IF @rate_date IS NULL SET @rate_date = @proc_date;

  DECLARE @base CHAR(3) =
    CONVERT(CHAR(3), JSON_VALUE(@payload, '$.base')) COLLATE SQL_Latin1_General_CP1_CI_AS;

  DELETE FROM dbo.dim_currency_rate
  WHERE rate_date = @rate_date AND src_currency = @base;

  INSERT INTO dbo.dim_currency_rate (rate_date, src_currency, dst_currency, rate)
  SELECT
    @rate_date,
    @base,
    CONVERT(CHAR(3), [key]) COLLATE SQL_Latin1_General_CP1_CI_AS,
    TRY_CONVERT(DECIMAL(18,8), [value])
  FROM OPENJSON(@payload, '$.rates');
END;
GO
