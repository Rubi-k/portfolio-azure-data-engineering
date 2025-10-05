CREATE TABLE IF NOT EXISTS dbo.dim_product(
  product_id INT PRIMARY KEY,
  name NVARCHAR(200),
  category NVARCHAR(100)
);
