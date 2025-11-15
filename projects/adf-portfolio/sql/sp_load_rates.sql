-- Load FX rates coming from an API payload (JSON) into dim_currency_rate
CREATE OR ALTER PROCEDURE dbo.sp_load_rates
  @proc_date  DATE,           -- Processing date (fallback if JSON doesn't include a date)
  @payload    NVARCHAR(MAX)   -- JSON returned by the API
AS
BEGIN
  SET NOCOUNT ON;

  ---------------------------------------------------------------------------
  -- 1) Extract the date from the JSON payload (payload.date)
  --    If the API doesn't send a valid date, fall back to @proc_date
  ---------------------------------------------------------------------------
  DECLARE @rate_date DATE = TRY_CONVERT(DATE, JSON_VALUE(@payload, '$.date'));
  IF @rate_date IS NULL SET @rate_date = @proc_date;

  ---------------------------------------------------------------------------
  -- 2) Extract the base currency (e.g., 'USD', 'EUR') from payload.base
  --    Collation is enforced to avoid collation mismatches when inserting.
  ---------------------------------------------------------------------------
  DECLARE @base CHAR(3) =
    CONVERT(CHAR(3), JSON_VALUE(@payload, '$.base')) COLLATE SQL_Latin1_General_CP1_CI_AS;

  ---------------------------------------------------------------------------
  -- 3) Remove any previously loaded rates for the same date + base currency
  --    This ensures idempotency: loading again replaces the dataset cleanly.
  ---------------------------------------------------------------------------
  DELETE FROM dbo.dim_currency_rate
  WHERE rate_date = @rate_date AND src_currency = @base;

  ---------------------------------------------------------------------------
  -- 4) Insert new rates
  --    OPENJSON expands the "rates" object into rows: key = currency, value = rate.
  --    Example JSON:
  --    "rates": { "EUR": 0.93, "GBP": 0.79, ... }
  --
  --    Each key/value becomes (dst_currency, rate)
  ---------------------------------------------------------------------------
  INSERT INTO dbo.dim_currency_rate (rate_date, src_currency, dst_currency, rate)
  SELECT
    @rate_date,                                   -- rate_date
    @base,                                        -- src_currency (e.g. USD)
    CONVERT(CHAR(3), [key]) COLLATE SQL_Latin1_General_CP1_CI_AS,  -- dst_currency
    TRY_CONVERT(DECIMAL(18,8), [value])           -- conversion rate
  FROM OPENJSON(@payload, '$.rates');             -- expands JSON object into rows
END;
GO
