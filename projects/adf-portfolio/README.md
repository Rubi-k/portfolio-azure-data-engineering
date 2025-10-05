# Azure Data Factory – Portfolio Project (Sprint 1)

## Overview
End-to-end batch ingestion that copies daily sales CSVs from **landing** to **staging**, validates empty files, and routes bad files to **errors**. Parameterized by `proc_date` to support reprocessing any partition.

## Architecture (high level)
- **Storage (ADLS Gen2)**: Containers `landing`, `staging`, `errors`.
  - Layout: `landing/sales/YYYY-MM-DD/*.csv` → `staging/sales/YYYY-MM-DD/*.csv`
  - Invalid/empty files: `errors/sales/YYYY-MM-DD/*.csv`
- **ADF**: Pipelines, datasets, triggers, and activities (Get Metadata, Filter, ForEach, Copy, Delete, If Condition).
- **Auth**: Managed Identity (recommended) or Storage key (temporary).

## Azure resources (example names)
- Resource Group: `rg-adf-portfolio-dev`
- Storage: `stportfoliodata`
- Data Factory: `adf-portfolio-devexec`

## Pipelines
### `pl_ingest_sales`
**Parameter**
- `proc_date` (string, format `YYYY-MM-DD`) — no default so manual runs prompt for it.

**Flow (inside ForEach)**
1) `get_landing_files` (Get Metadata on folder)
   - Dataset: `ds_csv_sales_landing`
   - Field list: **Child items**
2) `filter_csv` (Filter)
   - Items: `@activity('get_landing_files').output.childItems`
   - Condition: `@endsWith(toLower(item().name), '.csv')`
3) `fe_each_csv` (ForEach over filtered files)
   - Items: `@activity('filter_csv').output.Value`
   - Inside ForEach:
     - `gm_file_size` (Get Metadata on file)
       - Field list: **Size**
     - `if_size_ok` (If Condition)
       - Expression:
         ```
         @greater(coalesce(activity('gm_file_size').output.size, 0), 0)
         ```
       - **True** → `copy_to_staging`
         - Source: wildcard folder `@concat('sales/', pipeline().parameters.proc_date)`; wildcard file `@item().name`
         - Sink: dataset `ds_csv_sales_staging` (preserve file name, leave File/Extension blank)
         - On Failure → `copy_to_errors_onfail`
       - **False** → `copy_to_errors`
         - After success → `delete_from_landing` (Delete) to “move” file from landing

### Event Trigger (optional)
- **Type**: Blob created (container: `landing`)
- Begins with: `sales/`
- Ends with: *(blank) or `.csv` if you only want lowercase; filtering is handled in pipeline)*
- **Parameter mapping**
  - `proc_date`:
    ```
    @last(split(triggerBody().folderPath,'/'))
    ```
  - Works for structure `sales/YYYY-MM-DD/filename.csv`.

## Datasets
- **`ds_csv_sales_landing`** (folder-level)
  - Container: `landing`
  - Directory: `sales/@{dataset().p_proc_date}`
  - Parameters: `p_proc_date` (string)
- **`ds_csv_sales_landing_file`** (file-level)
  - Container: `landing`
  - Directory: `sales/@{dataset().p_proc_date}`
  - File: `@{dataset().p_file_name}`
  - Parameters: `p_proc_date`, `p_file_name`
- **`ds_csv_sales_staging`** (folder-level)
  - Container: `staging`
  - Directory: `sales/@{dataset().p_proc_date}`
  - Parameters: `p_proc_date`
- **`ds_csv_sales_errors`** (file-level)
  - Container: `errors` *(or staging with subfolder `errors/`)*
  - Directory: `sales/@{dataset().p_proc_date}`
  - File: `@{dataset().p_file_name}`
  - Parameters: `p_proc_date`, `p_file_name`

## Parameters wiring (examples)
- In Get Metadata (folder): `p_proc_date = @pipeline().parameters.proc_date`
- In file-level ops (Get Metadata Size / Copy / Delete):
  - `p_proc_date = @pipeline().parameters.proc_date`
  - `p_file_name = @item().name`

## Observability (minimal)
- **User properties** on key activities: `proc_date = @pipeline().parameters.proc_date`; inside ForEach add `file_name = @string(item().name)`
- **Metrics** via variables (optional):
  - Arrays: `v_ok_files`, `v_err_files`
  - Append in True/False branches; after ForEach set `ok_count = @length(variables('v_ok_files'))` and `err_count = @length(variables('v_err_files'))`

## How to run
### Manual (recommended while developing)
1. Upload files to: `landing/sales/<proc_date>/`
2. **Add Trigger → Trigger now**
3. Set `proc_date` to the matching date
4. Monitor → verify staging/errors outputs and activity user properties

### Event-based
- Upload file to `landing/sales/YYYY-MM-DD/`. The trigger passes `proc_date` automatically.

## Troubleshooting
- **PathNotFound / childItems = []**: check the folder exists at `landing/sales/<proc_date>/` and the dataset parameter mapping uses dynamic content.
- **Weird folder names like `@body('...').p_proc_date`**: remove any literal expressions from Sink; use **File path in dataset** and pass only dataset parameters; leave file/extension blank to preserve the source name.
- **AuthorizationPermissionMismatch**: make sure ADF Managed Identity has **Storage Blob Data Contributor** on the relevant containers (landing/staging/errors).

## Repository layout (suggested)
```
/docs
  architecture.md
  runbook.md
  data_dictionary.md
/adf
  pipelines/ (exported JSON)
  datasets/
/sql
  ddl_dim_product.sql
  ddl_dim_currency_rate.sql
  ddl_fact_sales.sql
  ddl_etl_audit.sql
/samples
  sales_*.csv
README.md
```

## Next steps (Sprint 2 preview)
- **Key Vault**: create vault, grant ADF MI `Secrets User`, store `api-exchange-key`.
- **Rates API**: `pl_enrich_rates` with Web activity + Copy/Mapping to `dim_currency_rate`.
- **Publish gold**: join sales + products + rates; write `fact_sales`.
