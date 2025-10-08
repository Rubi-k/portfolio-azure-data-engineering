-- sp_qc_publish_gold.sql (optional)
CREATE OR ALTER PROCEDURE dbo.sp_qc_publish_gold
  @d DATE
AS
BEGIN
  SET NOCOUNT ON;

  -- basic counts
  SELECT 'stg_rows' AS metric, COUNT(*) AS value
  FROM dbo.stg_sales WHERE CAST(sale_ts AS date)=@d
  UNION ALL
  SELECT 'fact_rows', COUNT(*) FROM dbo.fact_sales WHERE CAST(sale_ts AS date)=@d;

  -- staging rows missing in fact
  SELECT 'missing_in_fact' AS issue, s.*
  FROM dbo.stg_sales s
  LEFT JOIN dbo.fact_sales f ON f.sale_id=s.sale_id
  WHERE CAST(s.sale_ts AS date)=@d AND f.sale_id IS NULL;

  -- fact rows with null amount_usd
  SELECT 'null_amount_usd' AS issue, *
  FROM dbo.fact_sales
  WHERE CAST(sale_ts AS date)=@d AND amount_usd IS NULL;
END;
GO
