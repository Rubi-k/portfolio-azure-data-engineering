# Project 2 — Azure Databricks + Delta Lake (Medallion Architecture) — MovieLens (Reduced Subset)

This project implements a **Bronze → Silver → Gold** data pipeline on **Azure Databricks** with **Delta Lake** over a reduced subset of the **MovieLens 1M** dataset.  
The goal is to demonstrate cloud-based data engineering best practices while keeping the project feasible within the free Azure tier and a ~5-day time box.

> **Language policy:** All project files (code, docs, comments) are in **English**. Conversations may be in Spanish, but the portfolio remains in English.

---

## Dataset
- **Source:** [MovieLens 1M](https://grouplens.org/datasets/movielens/1m/)  
- **Files used:** `ratings.dat`, `movies.dat`  
- **Subset strategy:** Filter ratings by time window (e.g., years 2000–2005) to reduce size (~100k–200k rows).  
- **Schema (CSV):**
  - `ratings`: `userId,movieId,rating,timestamp`
  - `movies`: `movieId,title,genres` (pipe-separated genres like `Action|Adventure`)

---

## Architecture
The pipeline follows the **Medallion Architecture** pattern:

1. **Raw** → Original files (`.dat` or converted `.csv`) stored in ADLS.  
2. **Bronze** → Landing Delta tables with schema-on-read.  
3. **Silver** → Cleaned and standardized data (types fixed, deduplication, genres split into arrays).  
4. **Gold** → Business-ready models, e.g.:
   - `gold.avg_rating_per_genre`
   - `gold.top_movies_per_decade`
   - `gold.rating_distribution_per_user` (optional)

See `docs/architecture.png` for a visual diagram.

---

## Data Preparation

MovieLens is distributed in legacy `.dat` format with `::` delimiters. To enable efficient ingestion, we provide two alternatives:

### Option A — Python/Pandas (local preprocessing)
Script: [`scripts/convert_movielens_pandas.py`](scripts/convert_movielens_pandas.py)

**Usage example:**
```bash
# Activate the virtual environment first
.\.venv\Scriptsctivate

# Run conversion (filtering ratings from 2000 to 2005)
python project2-databricks-delta/scripts/convert_movielens_pandas.py   --ratings "C:/path/to/ml-1m/ratings.dat"   --movies "C:/path/to/ml-1m/movies.dat"   --outdir project2-databricks-delta/data/converted   --start-year 2000 --end-year 2005
```

This produces:
- `ratings_subset.csv` → filtered ratings  
- `movies.csv` → movies catalogue  

Upload these files into the **Raw** container in ADLS.

### Option B — Databricks (in-cluster conversion)
Notebook: [`notebooks/00_convert_dat_to_bronze.py`](notebooks/00_convert_dat_to_bronze.py)  
Reads `.dat` files directly from ADLS Raw and writes Bronze Delta tables.

---

## Requirements

A Python virtual environment is recommended. Install dependencies with:

```bash
# Create and activate venv (Windows CMD)
python -m venv .venv
.\.venv\Scriptsctivate.bat

# Or PowerShell
.\.venv\Scripts\Activate.ps1

# Install required packages
pip install -r requirements.txt
```

Currently only `pandas` is required for preprocessing. Future extensions may include `pyarrow`, `fastparquet`, or `azure-storage-blob`.

---

## Pipeline Components
- `notebooks/01_bronze_ingest.py` → Load CSV/Dat into Bronze Delta tables.  
- `notebooks/02_silver_transform.py` → Apply cleaning and transformations into Silver tables.  
- `notebooks/03_gold_models.py` → Generate Gold-level analytical models.  
- `sql/gold_validation.sql` → Validation queries against Gold tables.  
- `docs/architecture.png` → Architecture diagram.  
- `scripts/convert_movielens_pandas.py` → Optional preprocessing step.  

---

## Professional Notes
- Secrets and credentials are not committed; use **Azure Key Vault** or **Databricks Secrets**.  
- Use a small, single-node cluster with **auto-terminate** to minimize costs.  
- Delta + Parquet storage reduces costs and improves query performance.  

---

## Outcome
This project demonstrates:  
- End-to-end ingestion and transformation pipeline (Raw → Bronze → Silver → Gold).  
- Experience with **Azure Databricks**, **Delta Lake**, and **ADLS**.  
- Good practices in data preparation, documentation, and cost optimization.  
