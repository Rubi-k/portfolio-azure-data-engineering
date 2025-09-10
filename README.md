# Azure Data Engineering Portfolio

## 🌍 About this Repository
This repository showcases practical **Data Engineering projects on Microsoft Azure**, designed as a portfolio for recruiters and hiring managers.  
It includes **end-to-end pipelines, documentation, and architecture diagrams** to demonstrate hands-on experience with Azure services.

---

## 🚀 Projects

### 1. ETL with Azure Data Factory & Synapse Serverless
- **Ingest** raw CSV files from Azure Blob Storage (`rawdata` container).  
- **Transform** data using Azure Data Factory (Mapping Data Flows).  
- **Store** cleansed data as partitioned Parquet files in the `curated` container.  
- **Expose** curated data with Synapse serverless external tables and business views.  

👉 [See project details](project1-adf-synapse/docs/README.md)

---

### 2. Mini Lakehouse with Databricks & Delta Lake
- **Ingest** data into a Bronze Delta table.  
- **Transform** into Silver and Gold layers with Databricks notebooks.  
- **Enable** analytics with Databricks SQL and/or Synapse serverless.  
- **Focus** on Delta Lake best practices, schema evolution, and partitioning.  

👉 (Coming soon)

---

## 🛠️ Technologies Used
- **Azure Data Factory** – Orchestration & ETL  
- **Azure Synapse (Serverless SQL)** – Data exposure & analytics  
- **Azure Blob Storage** – Data lake zones (raw, curated, gold)  
- **Azure Databricks + Delta Lake** – Lakehouse architecture  
- **Power BI (optional)** – Reporting & dashboards  

---

## 📸 Portfolio Artifacts
Each project includes:
- **Architecture diagrams** (Mermaid/draw.io)  
- **Screenshots** of Azure resources and pipelines  
- **Source code & SQL scripts**  
- **Documentation** for reproducibility  

---

## 👨‍💻 Author
Built by **Ruben Kaplan** – Data Engineer with hands-on experience in Azure Data Factory, Synapse, Databricks, and Delta Lake.  
Open to remote opportunities in English-speaking environments.  

---

## 📌 Notes
This portfolio was developed using an **Azure free trial subscription**, optimized for **low cost** and **quick deployment**.  
