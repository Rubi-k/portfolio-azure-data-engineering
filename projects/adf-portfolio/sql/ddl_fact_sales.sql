CREATE TABLE IF NOT EXISTS dbo.fact_sales(
  sale_id BIGINT PRIMARY KEY,
  product_id INT NOT NULL,
  sale_ts DATETIME2 NOT NULL,
  qty INT NOT NULL,
  amount_src DECIMAL(18,2) NOT NULL,
  currency_src CHAR(3) NOT NULL,
  amount_usd DECIMAL(18,2) NULL,
  CONSTRAINT FK_fact_sales_product FOREIGN KEY(product_id) REFERENCES dbo.dim_product(product_id)
);
