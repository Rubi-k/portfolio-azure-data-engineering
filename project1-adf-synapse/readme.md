This project demonstrates how to build an **end-to-end data pipeline in Azure**, combining:

- **Azure Data Factory (ADF)** → orchestrates data movement and transformation  
- **Azure Blob Storage** → landing zone for raw files and curated zone for transformed data  
- **Azure Synapse Serverless** → exposes curated data for SQL analytics  

The pipeline follows a **raw → curated → analytics** pattern:

1. **Raw** → CSV files (e.g., `customers.csv`) are uploaded into the `rawdata` container  
2. **Curated** → ADF pipelines convert CSVs into **Parquet** format inside the `curated` container  
3. **Analytics** → Curated data is exposed as **external tables** in Synapse for reporting and BI  

---

## 📖 Full Documentation
👉 Full walkthrough with architecture diagram, SQL scripts, and screenshots:  
[`/docs/README.md`](docs/README.md)
