
# Databricks notebook source
# MAGIC %md
# MAGIC # 03 — Gold Models (MovieLens — Reduced Subset)
# MAGIC Build business-ready **Gold** tables and views using Silver:
# MAGIC - `avg_rating_per_genre`
# MAGIC - `top_movies_per_decade`

# COMMAND ----------
from pyspark.sql import functions as F
from pyspark.sql.window import Window

dbutils.widgets.text("silver_base_path", "")
dbutils.widgets.text("gold_base_path", "")

silver_base_path = dbutils.widgets.get("silver_base_path")
gold_base_path = dbutils.widgets.get("gold_base_path")

assert silver_base_path and gold_base_path, "Set silver_base_path and gold_base_path."

ratings = spark.read.format("delta").load(f"{silver_base_path}/ratings")
movies  = spark.read.format("delta").load(f"{silver_base_path}/movies")

# Explode genres and compute average rating per genre
ratings_simple = ratings.select("movieId", "rating", "rating_ts")
movies_exp = (movies
    .withColumn("genre", F.explode_outer(F.col("genres_arr")))
    .select("movieId", "title", "genre")
)

avg_rating_per_genre = (ratings_simple
    .join(movies_exp, "movieId", "inner")
    .groupBy("genre")
    .agg(F.count("*").alias("n_ratings"),
         F.avg("rating").alias("avg_rating"))
    .orderBy(F.desc("avg_rating"))
)

path_genre = f"{gold_base_path}/avg_rating_per_genre"
(avg_rating_per_genre.write.mode("overwrite").format("delta").save(path_genre))
spark.sql(f"CREATE TABLE IF NOT EXISTS gold_avg_rating_per_genre USING DELTA LOCATION '{path_genre}'")

display(spark.read.format("delta").load(path_genre).orderBy(F.desc("avg_rating")).limit(20))

# Compute top movies per decade by average rating (with a minimal rating count threshold)
ratings_with_year = ratings_simple.withColumn("year", F.year("rating_ts"))
decade_df = ratings_with_year.withColumn("decade", (F.col("year")/10).cast("int")*10)

movie_stats = (decade_df
    .groupBy("movieId", "decade")
    .agg(F.count("*").alias("n_ratings"),
         F.avg("rating").alias("avg_rating"))
    .where(F.col("n_ratings") >= 50)  # threshold to avoid noise
)

top_movies_per_decade = (movie_stats
    .join(movies.select("movieId", "title"), "movieId", "left")
    .withColumn("rank", F.row_number().over(Window.partitionBy("decade").orderBy(F.desc("avg_rating"))))
    .where(F.col("rank") <= 10)
    .select("decade", "rank", "movieId", "title", "avg_rating", "n_ratings")
    .orderBy("decade", "rank")
)

path_top = f"{gold_base_path}/top_movies_per_decade"
(top_movies_per_decade.write.mode("overwrite").format("delta").save(path_top))
spark.sql(f"CREATE TABLE IF NOT EXISTS gold_top_movies_per_decade USING DELTA LOCATION '{path_top}'")

display(spark.read.format("delta").load(path_top).limit(50))
