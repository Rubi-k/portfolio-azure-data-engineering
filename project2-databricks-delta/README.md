# Project 2 — Databricks + Delta Lake (Medallion Architecture) — MovieLens (Reduced Subset)

This project demonstrates a **Bronze → Silver → Gold pipeline** on **Azure Databricks** with **Delta Lake**, using a reduced subset of the **MovieLens 1M dataset**. The goal is to showcase solid Data Engineering practices in a portfolio-friendly and cost-efficient way, suitable for the free Azure tier.

> **Language policy:** All project files (code, docs, comments) are in **English**. Conversations may be in Spanish, but the portfolio remains in English.

---

## Dataset
- **Source:** [MovieLens 1M](https://grouplens.org/datasets/movielens/1m/)
- **Files used:** `ratings.dat`, `movies.dat` (converted to CSV).
- **Subset strategy:** Ratings filtered by year range (e.g., 2000–2005) to target ~100k–200k rows.
- **CSV schemas:**
  - `ratings`: `userId,movieId,rating,timestamp`
  - `movies`: `movieId,title,genres` (pipe-separated genres like `Action|Adventure`)

---

## Pipeline Overview
- **Bronze**: Land raw files into Delta (schema-on-read, append/full loads).
- **Silver**: Clean types, normalize strings, deduplicate, convert timestamps, split genres into arrays.
- **Gold**: Analytics-ready models:
  - `gold.avg_rating_per_genre`
  - `gold.top_movies_per_decade`
  - (optional) `gold.rating_distribution_per_user`

---

## Repository Structure
```
project2-databricks-delta/
│
├── config/                     # Example configs (no secrets)
├── docs/                       # Documentation & architecture diagrams
├── notebooks/                  # Databricks notebooks for Bronze/Silver/Gold
├── scripts/                    # Utility scripts (e.g., DAT → CSV conversion)
├── sql/                        # Validation queries for Gold
├── workflows/                  # Databricks Workflow templates
└── requirements.txt            # Python dependencies (local dev)
```

---

## Usage

### 1. Prepare Data
Convert MovieLens `.dat` files to CSV:
- **Option A (local)**: Use Python/Pandas script in `scripts/convert_movielens_pandas.py`.
- **Option B (Databricks)**: Ingest `.dat` files directly via Spark with custom delimiter.

Reason: CSV provides cleaner schema inference and avoids encoding issues.

### 2. Run Pipeline
- Import and run notebooks sequentially:
  1. `01_bronze_ingest.py`
  2. `02_silver_transform.py`
  3. `03_gold_models.py`

### 3. Validate
Run SQL queries in `sql/gold_validation.sql` to confirm results.

---

## Notes
- Avoid committing secrets — use **Key Vault** or **Databricks secrets**.
- Use a single-node cluster with **auto-terminate** to minimize cost.
- Delta + Parquet reduces storage footprint and improves query performance.

---

## Outcomes
- A clean, professional pipeline demonstrating **Medallion Architecture**.
- Optimized for **portfolio showcasing** and **Azure free-tier cost control**.
- Recruiters can see both engineering skills and best practices.
