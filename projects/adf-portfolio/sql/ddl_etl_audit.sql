CREATE TABLE IF NOT EXISTS dbo.etl_audit(
  run_id UNIQUEIDENTIFIER DEFAULT NEWID(),
  pipeline_name NVARCHAR(200),
  proc_date DATE,
  rows_processed INT,
  status NVARCHAR(20),
  error_message NVARCHAR(2000),
  started_at DATETIME2 DEFAULT SYSUTCDATETIME(),
  finished_at DATETIME2 NULL
);
