CREATE TABLE IF NOT EXISTS dbo.dim_currency_rate(
  rate_date DATE,
  src_currency CHAR(3),
  dst_currency CHAR(3) NOT NULL DEFAULT 'USD',
  rate DECIMAL(18,8) NOT NULL,
  CONSTRAINT PK_dim_currency_rate PRIMARY KEY (rate_date, src_currency, dst_currency)
);
