# Azure Data Factory Portfolio — Sales Ingestion → Enrichment → Publish (with Gold Parquet)

A production-style data pipeline built with **Azure Data Factory (ADF)**, **Azure Data Lake Storage Gen2 (ADLS)**, **Azure Key Vault**, and **Azure SQL Database**.

It ingests raw CSV sales files from a *landing* zone, validates and stages them, enriches with **FX rates from API Layer (APILayer)** using a Key Vault–backed secret, publishes a curated **`fact_sales`** table in SQL (amounts normalized to USD), and exports a **partitioned Parquet** artifact to an ADLS **gold** container. Designed to demonstrate interview-ready ADF skills: triggers, parameterization, activities, error handling, security, idempotent SQL loads, and downstream gold datasets.

---

## Highlights

- **Event-driven ingestion** (Blob Created) with `proc_date` inferred from the folder path.
- **Robust file handling**: GetMetadata → Filter → ForEach → Copy; empty files routed to `errors/`; optional Delete to “move” instead of copy.
- **Secure API integration**: Key Vault secret → Web activity → APILayer `exchangerates_data` with `apikey` header.
- **Idempotent loads**: DELETE+INSERT for FX rates; MERGE for `fact_sales`; safe reprocess by date.
- **Master orchestration**: single `proc_date` drives **ingest → rates → publish → gold**.
- **Gold layer**: date-partitioned Parquet in ADLS (`year=/month=/day=`), ready for analytics engines.

---

## Architecture (high-level)

- **Storage (ADLS Gen2)**: containers `landing/`, `staging/`, `errors/`, `gold/`
- **Pipelines**
  - `pl_ingest_sales`: enumerate → filter → copy valid CSVs to `staging/`; empty to `errors/`; optional Delete in `landing/`
  - `pl_enrich_rates`: Web (Managed Identity → Key Vault) → Web (FX API) → Stored Procedure (`sp_load_rates`)
  - `pl_publish_gold`: Copy (staging → SQL `stg_sales`) → Stored Procedure (`sp_publish_sales`) → Copy (SQL → ADLS Parquet gold)
  - `pl_orchestrate_day`: chains the three with the same `proc_date`
- **Security**: Key Vault secret (API key), ADF Managed Identity access to Key Vault and Storage, least-privilege SQL grants
- **SQL**: `dim_currency_rate`, `stg_sales`, `fact_sales`

---

## Repository structure

```
projects/
└─ adf-portfolio/
   ├─ adf/                      # ADF ARM export (pipelines, datasets, linked services)
   ├─ sql/                      # SQL DDL & procedures
   ├─ docs/                     # architecture, runbook, screenshots
   ├─ samples/                  # optional sample CSVs for landing
   └─ README.md                 # (this file)
```

---

## Prerequisites

- Azure subscription with permissions to create ADF, ADLS Gen2, Key Vault, Azure SQL
- ADF Managed Identity with:
  - **Key Vault Secrets User** on the Key Vault
  - **Storage Blob Data Contributor** on the Storage account (containers `landing`, `staging`, `errors`, `gold`)
- Azure SQL user/MI with `EXEC` on SPs and `SELECT/INSERT/UPDATE/DELETE` on staging/publish tables
- **APILayer** account (Exchange Rates Data). Create a secret in Key Vault, e.g. `api-exchange-key`

---

## Configuration

### Key Vault
- Secret: `api-exchange-key` = your APILayer **API key**
- ADF Web activity calls Key Vault using **Managed Identity** to retrieve the secret at runtime.

### APILayer (Exchange Rates Data)
- Base URL (linked service): `https://api.apilayer.com/exchangerates_data/` (note the trailing `/`)
- Header: `apikey: <value from Key Vault>`
- Example relative URL (by date):  
  `2025-10-07?symbols=USD,EUR,GBP&base=USD`
  - Some free plans do **not** allow `base != EUR`. If so, either use `EUR` or omit `base`.

### ADLS Containers
- `landing/`, `staging/`, `errors/`, `gold/`

---

## Deployment

### ADF (ARM) — recommended for this portfolio
- Import/Export ARM template from `projects/adf-portfolio/adf/`  
  (_Alternatively, use ADF Git integration and publish to your factory_.)

### SQL
Run the scripts in `projects/adf-portfolio/sql/`:
- `create_tables.sql`
- `sp_load_rates.sql` (simple DELETE+INSERT from JSON)
- `sp_publish_sales.sql` (MERGE into `fact_sales`)
- (Optional) `sp_qc_publish_gold.sql`

---

## Parameters

- `proc_date` (string `YYYY-MM-DD`): processing date used for folder paths and SQL joins
- `p_base` (string): base currency for the FX call (`USD` or `EUR`)

---

## Pipelines

### 1) `pl_ingest_sales`
- **Input**: CSVs in `landing/sales/{proc_date}/*.csv`
- **Flow**: GetMetadata (Child items) → Filter (`*.csv`) → ForEach → Copy to `staging/sales/{proc_date}/`  
  Empty files are routed to `errors/sales/{proc_date}/`. Optional **Delete** in `landing` to “move” instead of copy.
- **Parameterization**: folder path is driven by `proc_date`.
- **User properties**: `proc_date` for easy Monitor filtering

### 2) `pl_enrich_rates`
- **Web** `kv_get_secret`: GET Key Vault secret (Managed Identity)
- **Web** `web_get_rates`: call `https://api.apilayer.com/exchangerates_data/{proc_date}?symbols=USD,EUR,GBP[&base=USD]`
  - Header: `apikey = (value from kv_get_secret)`
- **Stored Procedure** `sp_load_rates(@proc_date, @payload)`
  - `@payload` is the JSON string from `web_get_rates.output`

### 3) `pl_publish_gold`
- **Copy** staging → SQL (`dbo.stg_sales`) with a **pre-delete by date**
- **Stored Procedure** `sp_publish_sales(@proc_date, @rates_base)`
  - Computes `amount_usd` using FX for that date; MERGEs into `dbo.fact_sales`
- **Copy** SQL → ADLS **Parquet** (gold), **partitioned by date**:
  - Path: `gold/sales/year={yyyy}/month={MM}/day={dd}/part-0000.parquet`
  - Overwrite enabled for idempotent reprocess

### 4) `pl_orchestrate_day`
- Executes: `pl_ingest_sales` → `pl_enrich_rates` → `pl_publish_gold`
- **Parameters**: `proc_date` (required), `p_base` (default `USD`)
- **Retries** (recommended): ingest(1×30s), rates(3×30s), publish(1×30s)

---

## Triggers

### Event Trigger (Blob Created) — recommended
- Container: `landing`
- Begins with: `sales/`
- Parameter mapping:
  ```text
  proc_date = @last(split(triggerBody().folderPath,'/'))
  p_base    = 'USD'   // or 'EUR' if your plan requires it
  ```

### Schedule Trigger (optional)
- Daily at HH:MM UTC (e.g., 09:00 UTC for 06:00 Argentina)
- Parameters:
  ```text
  proc_date = @formatDateTime(addDays(utcNow(), -1),'yyyy-MM-dd')
  p_base    = 'USD'
  ```

---

## Gold layer (Partitioned Parquet in ADLS)

After publishing to SQL (`fact_sales`), the pipeline writes a Parquet extract to ADLS in a date-partitioned layout:

- Container: `gold`
- Path pattern:
  ```
  gold/sales/year={yyyy}/month={MM}/day={dd}/part-0000.parquet
  ```
- Example for `proc_date=2025-10-07`:
  ```
  gold/sales/year=2025/month=10/day=07/part-0000.parquet
  ```
- Schema: `sale_id, product_id, sale_ts, qty, amount_src, currency_src, amount_usd`
- Idempotent reprocess: the file is overwritten when re-running the same `proc_date`.

---

## How to run

### A) Event-driven
1. Upload CSVs to `landing/sales/YYYY-MM-DD/*.csv` (e.g., `landing/sales/2025-10-07/`).
2. The event trigger fires `pl_orchestrate_day` with that `proc_date`.

### B) Manual (reprocess any date)
- `pl_orchestrate_day` → **Trigger now** with:
  - `proc_date = 2025-10-07`
  - `p_base = USD` (or `EUR`)

---

## Validation (SQL)

```sql
DECLARE @d date = 'YYYY-MM-DD';

-- Rates
SELECT COUNT(*) FROM dbo.dim_currency_rate WHERE rate_date=@d;

-- Staging vs Fact counts
SELECT
  (SELECT COUNT(*) FROM dbo.stg_sales  WHERE CAST(sale_ts AS date)=@d) AS stg_rows,
  (SELECT COUNT(*) FROM dbo.fact_sales WHERE CAST(sale_ts AS date)=@d) AS fact_rows;

-- Rows in staging not present in fact
SELECT s.*
FROM dbo.stg_sales s
LEFT JOIN dbo.fact_sales f ON f.sale_id = s.sale_id
WHERE CAST(s.sale_ts AS date) = @d
  AND f.sale_id IS NULL;

-- Null USD amounts (should be rare; indicates missing FX for currency/date)
SELECT * FROM dbo.fact_sales
WHERE CAST(sale_ts AS date)=@d AND amount_usd IS NULL;
```

> See the optional `sp_qc_publish_gold.sql` for a consolidated QC routine.

---

## Troubleshooting

- **400 from FX API**: Ensure no quotes/spaces in the URL (e.g., `base=USD`, not `base='USD'`), and base URL ends with `/`.
- **401 (Unauthorized)**: Validate the Key Vault secret and that the `apikey` header is being set from `kv_get_secret`.
- **SQL permission denied**: Grant the ADF identity `EXEC` on SPs and DML on `stg_sales` (DELETE/INSERT/UPDATE as needed).
- **Folder parameter is null**: Confirm the event trigger is on the **master** pipeline and maps `proc_date` from `triggerBody().folderPath`.

---

## Security notes

- The API key is stored in **Key Vault** and pulled at runtime via **Managed Identity**.
- No secrets are committed to the repository.
- Least-privilege SQL permissions are used (staging DML, SP EXEC).

---

## Cost & performance (quick tips)

- Add retries to the API call to handle transient failures.
- Keep files reasonable in size; consider batching if needed.
- Prefer Parquet for gold to reduce storage and improve downstream performance.

---

## Next steps (nice-to-have)

- Email/Teams alert on failure (Logic App/Webhook).
- Simple audit table (`etl_audit`) written by ADF with row counts and durations.
- CI/CD via ARM/Bicep with parameterized environments.
- External view on gold Parquet for serverless analytics.

---

## License

ECL-2.0

