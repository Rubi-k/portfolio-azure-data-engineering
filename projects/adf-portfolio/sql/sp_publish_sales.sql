-- sp_publish_sales.sql
CREATE OR ALTER PROCEDURE dbo.sp_publish_sales
  @proc_date   DATE,
  @rates_base  CHAR(3)   -- 'USD' or 'EUR'
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH src AS (
    SELECT sale_id, product_id, sale_ts, qty, amount_src, currency_src,
           CAST(sale_ts AS date) AS rate_date
    FROM dbo.stg_sales
    WHERE CAST(sale_ts AS date) = @proc_date
  ),
  usd AS (
    SELECT rate_date, dst_currency, rate
    FROM dbo.dim_currency_rate
    WHERE rate_date = @proc_date AND src_currency='USD'
  ),
  eur AS (
    SELECT rate_date, dst_currency, rate
    FROM dbo.dim_currency_rate
    WHERE rate_date = @proc_date AND src_currency='EUR'
  ),
  eur_to_usd AS (
    SELECT rate_date, MAX(CASE WHEN dst_currency='USD' THEN rate END) AS eur_to_usd
    FROM eur GROUP BY rate_date
  ),
  calc AS (
    SELECT 
      s.sale_id, s.product_id, s.sale_ts, s.qty, s.amount_src, s.currency_src,
      CASE 
        WHEN @rates_base='USD' THEN
          CASE WHEN s.currency_src='USD' THEN s.amount_src
               ELSE s.amount_src / u.rate END
        WHEN @rates_base='EUR' THEN
          CASE WHEN s.currency_src='USD' THEN s.amount_src
               WHEN s.currency_src='EUR' THEN s.amount_src * eu.eur_to_usd
               ELSE s.amount_src * (eu.eur_to_usd / e.rate) END
        ELSE NULL
      END AS amount_usd
    FROM src s
    LEFT JOIN usd u ON @rates_base='USD' AND u.rate_date=s.rate_date AND u.dst_currency=s.currency_src
    LEFT JOIN eur e ON @rates_base='EUR' AND e.rate_date=s.rate_date AND e.dst_currency=s.currency_src
    LEFT JOIN eur_to_usd eu ON @rates_base='EUR' AND eu.rate_date=s.rate_date
  )
  MERGE dbo.fact_sales AS tgt
  USING calc AS c ON tgt.sale_id = c.sale_id
  WHEN MATCHED THEN UPDATE SET
    product_id=c.product_id, sale_ts=c.sale_ts, qty=c.qty,
    amount_src=c.amount_src, currency_src=c.currency_src, amount_usd=c.amount_usd
  WHEN NOT MATCHED THEN
    INSERT (sale_id, product_id, sale_ts, qty, amount_src, currency_src, amount_usd)
    VALUES (c.sale_id, c.product_id, c.sale_ts, c.qty, c.amount_src, c.currency_src, c.amount_usd);
END;
GO
