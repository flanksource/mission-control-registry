CREATE TABLE #rds_tasks (
  task_id INT,
  task_type VARCHAR(255),
  database_name VARCHAR(255),
  percent_complete FLOAT,
  duration_mins INT,
  lifecycle VARCHAR(50),
  task_info NVARCHAR(MAX),
  last_updated DATETIME,
  created_at DATETIME,
  S3_object_arn NVARCHAR(MAX),
  overwrite_S3_backup_file BIT,
  KMS_master_key_arn NVARCHAR(MAX),
  filepath NVARCHAR(MAX),
  overwrite_file BIT
);

INSERT INTO #rds_tasks
EXEC msdb.dbo.rds_task_status;

SELECT
 database_name,
  CAST(task_id AS VARCHAR(36)) as task_id,
  task_type as change_type,
  '% Complete: ' + CAST(percent_complete AS VARCHAR(10)) + ' - ' + ISNULL(task_info, '') as summary,
  CASE WHEN lifecycle IN ('ERROR') THEN 'high'
      WHEN lifecycle IN ('CANCELLED') THEN 'med'
      WHEN lifecycle IN ('SUCCESS') THEN 'low'
       ELSE 'info' END as severity,
  created_at,
  last_updated,
  task_info as details
FROM #rds_tasks
WHERE last_updated > DATEADD(hour, -24, GETDATE())
ORDER BY last_updated DESC;

DROP TABLE #rds_tasks;
