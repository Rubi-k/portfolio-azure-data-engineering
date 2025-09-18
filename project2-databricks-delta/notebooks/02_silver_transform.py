
# Databricks notebook source
# MAGIC %md
# MAGIC # 02 — Silver Transform (MovieLens — Reduced Subset)
# MAGIC Clean, standardize, and deduplicate Bronze into **Silver Delta** tables.
# MAGIC - Cast types, trim strings
# MAGIC - Convert `timestamp` (epoch seconds) to `timestamp`
# MAGIC - Split `genres` (pipe-separated) into an array

# COMMAND ----------
from pyspark.sql import functions as F
from pyspark.sql.window import Window
from pyspark.sql.types import *

dbutils.widgets.text("bronze_base_path", "")
dbutils.widgets.text("silver_base_path", "")
dbutils.widgets.text("table_name", "ratings")   # ratings | movies

bronze_base_path = dbutils.widgets.get("bronze_base_path")
silver_base_path = dbutils.widgets.get("silver_base_path")
table_name = dbutils.widgets.get("table_name").lower()

assert bronze_base_path and silver_base_path, "Set bronze_base_path and silver_base_path."
assert table_name in ["ratings", "movies"], "table_name must be 'ratings' or 'movies'."

bronze_path = f"{bronze_base_path}/{table_name}"
silver_path = f"{silver_base_path}/{table_name}"

df = spark.read.format("delta").load(bronze_path)

if table_name == "ratings":
    df_std = (df
        .withColumn("userId", F.col("userId").cast("int"))
        .withColumn("movieId", F.col("movieId").cast("int"))
        .withColumn("rating", F.col("rating").cast("double"))
        .withColumn("timestamp", F.col("timestamp").cast("long"))
        .withColumn("rating_ts", F.to_timestamp(F.col("timestamp")))
        .drop("timestamp")
    )
elif table_name == "movies":
    # Trim strings and split genres
    df_std = (df
        .withColumn("movieId", F.col("movieId").cast("int"))
        .withColumn("title", F.trim(F.col("title")))
        .withColumn("genres", F.trim(F.col("genres")))
        .withColumn("genres_arr", F.split(F.col("genres"), "\\|"))
    )

# Deduplicate
df_std = df_std.dropDuplicates()

# Write idempotently
(df_std.write.mode("overwrite").format("delta").save(silver_path))
spark.sql(f"CREATE TABLE IF NOT EXISTS silver_{table_name} USING DELTA LOCATION '{silver_path}'")

display(spark.read.format("delta").load(silver_path).limit(10))

# Basic data-quality checks
checks = spark.read.format("delta").load(silver_path).agg(F.count('*').alias('rows'))
display(checks)
