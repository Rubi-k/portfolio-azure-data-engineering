# Project 1 – ETL with Azure Data Factory & Synapse Serverless

## 📌 Summary
This project shows how to build a **data pipeline in Azure** using:
- **Azure Data Factory (ADF)** → to orchestrate data movement.
- **Azure Blob Storage** → as raw and curated storage.
- **Azure Synapse Serverless** → to expose curated data for analytics.

The pipeline follows a **raw → curated → analytics** approach:
- Raw CSV files (e.g., `customers.csv`) in **`rawdata`**.
- Converted to **Parquet** in **`curated`**.
- Later exposed as external tables in **Synapse**.

---

## 📖 Full Documentation
👉 See detailed steps, diagrams, and screenshots in  
[`/docs/README.md`](docs/README.md)
