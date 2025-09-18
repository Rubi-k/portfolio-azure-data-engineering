
# Project 2 — Databricks + Delta Lake (Medallion Architecture) — MovieLens (Reduced Subset)

This project implements a **Bronze → Silver → Gold** pipeline on **Azure Databricks** with **Delta Lake** over a **reduced subset** of the **MovieLens 1M** dataset. The goal is to be realistic while staying friendly to the free Azure tier and a ~5-day time box.

> **Language policy:** All project files (code, docs, comments) are in **English**. Conversations may be in Spanish, but the portfolio remains in English.

## Dataset
- **Source:** MovieLens (1M) — https://grouplens.org/datasets/movielens/1m/
- **Files used:** `ratings.dat`, `movies.dat` (or CSV equivalents depending on the chosen mirror).
- **Subset strategy:** Filter ratings by time window (e.g., years 2000–2005) to target ~100k–200k rows. You may also downsample users or movies if needed.
- **Suggested schema (CSV):**
  - `ratings`: `userId,movieId,rating,timestamp`
  - `movies`: `movieId,title,genres` (pipe-separated genres like `Action|Adventure`)

## Pipeline Overview
- **Bronze**: land raw files as-is into Delta (append/full modes, schema-on-read).
- **Silver**: clean types, trim strings, deduplicate; convert `timestamp` to `timestamp`; split `genres` into an array.
- **Gold**: business-ready models:
  - `gold.avg_rating_per_genre`
  - `gold.top_movies_per_decade`
  - (optional) `gold.rating_distribution_per_user`

## Contents
- `notebooks/01_bronze_ingest.py` — Ingest raw files to **Bronze Delta** (`ratings` / `movies`).
- `notebooks/02_silver_transform.py` — Clean and standardize **Silver** tables.
- `notebooks/03_gold_models.py` — Build **Gold** models for analytics.
- `workflows/databricks_workflow.json` — Databricks Workflows template.
- `sql/gold_validation.sql` — Validation queries.
- `docs/architecture.png` — Architecture diagram placeholder.
- `config/connection_example.json` — Example configuration (no secrets).

## Quick Start
1. **Configure access**
   - Use Azure Managed Identity or a Service Principal + Databricks Secret Scope.
   - Copy `config/connection_example.json` → `config/connection.json` and set your paths (do not commit credentials).

2. **Prepare reduced subset**
   - Place your filtered CSVs under `abfss://raw@<account>.dfs.core.windows.net/movielens/ratings/` and `.../movies/`.
   - If you keep the full 1M files, filter in a separate step to keep compute/storage costs low.

3. **Run Day 1**
   - Import `notebooks/01_bronze_ingest.py` and run for `table_name=ratings` and `table_name=movies`.
   - Verify Bronze counts and samples.

4. **Run Day 2**
   - Import and run `notebooks/02_silver_transform.py` for both `ratings` and `movies`.
   - Confirm basic data-quality checks.

5. **Run Day 3**
   - Run `notebooks/03_gold_models.py` and then execute `sql/gold_validation.sql` against Gold tables.

6. **Orchestration (Day 4)**
   - Import `workflows/databricks_workflow.json` into Databricks Workflows.
   - Parameterize a `run_mode` (full/incremental) if needed.

7. **Docs (Day 5)**
   - Replace the placeholder diagram and add screenshots of successful runs to `docs/images/`.
   - Document validation outputs and key insights for recruiters.

## Notes
- Keep secrets out of Git; prefer **Key Vault** or **Databricks secrets**.
- Use a small, single-node cluster with **auto-terminate**.
- Delta + Parquet reduces storage and improves query performance.
