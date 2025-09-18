
# Databricks notebook source
# MAGIC %md
# MAGIC # 01 — Bronze Ingest (MovieLens — Reduced Subset)
# MAGIC Ingest raw CSV/TSV files (`ratings`, `movies`) from ADLS Gen2 into **Bronze Delta** tables.
# MAGIC - Supports `full` and `incremental` (append) modes
# MAGIC - Schema-on-read with minimal transformations

# COMMAND ----------
from pyspark.sql import functions as F
from pyspark.sql.types import *
from datetime import datetime

# Widgets / parameters
dbutils.widgets.text("raw_base_path", "")
dbutils.widgets.text("bronze_base_path", "")
dbutils.widgets.text("run_mode", "full")             # full | incremental
dbutils.widgets.text("table_name", "ratings")        # ratings | movies
dbutils.widgets.text("delimiter", ",")               # "," for CSV or "::" for legacy .dat

raw_base_path = dbutils.widgets.get("raw_base_path")
bronze_base_path = dbutils.widgets.get("bronze_base_path")
run_mode = dbutils.widgets.get("run_mode")
table_name = dbutils.widgets.get("table_name").lower()
delimiter = dbutils.widgets.get("delimiter")

assert raw_base_path and bronze_base_path, "Set raw_base_path and bronze_base_path widgets."
assert table_name in ["ratings", "movies"], "table_name must be 'ratings' or 'movies'."

source_path = f"{raw_base_path}/{table_name}/"
target_path = f"{bronze_base_path}/{table_name}"

print(f"Reading {table_name} from {source_path} -> writing Delta at {target_path} (mode={run_mode})")

# COMMAND ----------
# Read raw (CSV/TSV). For MovieLens legacy .dat with '::' use delimiter='::' and no header.
infer_schema = True
header = "true" if delimiter == "," else "false"

if table_name == "ratings":
    schema = StructType([
        StructField("userId", IntegerType(), True),
        StructField("movieId", IntegerType(), True),
        StructField("rating", DoubleType(), True),
        StructField("timestamp", LongType(), True),
    ])
    df = (spark.read
          .option("delimiter", delimiter)
          .option("header", header)
          .schema(schema if delimiter!="," else None)
          .csv(source_path))
elif table_name == "movies":
    # For CSV: movieId,title,genres
    df = (spark.read
          .option("delimiter", delimiter)
          .option("header", header)
          .csv(source_path))

# Add ingestion metadata
df_bronze = (df
    .withColumn("_ingest_ts", F.current_timestamp())
    .withColumn("_ingest_date", F.to_date(F.current_timestamp()))
)

# Write as Delta
(df_bronze.write
    .mode("overwrite" if run_mode=="full" else "append")
    .format("delta")
    .save(target_path))

spark.sql(f"CREATE TABLE IF NOT EXISTS bronze_{table_name} USING DELTA LOCATION '{target_path}'")

display(spark.read.format("delta").load(target_path).limit(10))

# COMMAND ----------
# Sanity checks
display(spark.read.format("delta").load(target_path).agg(F.count('*').alias('row_count')))
