SELECT
 database_name,
  CAST(task_id AS VARCHAR(36)) as task_id,
  task_type as change_type,
  CAST([% Complete] AS VARCHAR(10)) + '% - ' + ISNULL(task_info, '') as summary,
  CASE WHEN lifecycle IN ('ERROR') THEN 'high'
      WHEN lifecycle IN ('CANCELLED') THEN 'med'
      WHEN lifecycle IN ('SUCCESS') THEN 'low'
       ELSE 'info' END as severity,
  created_at,
  last_updated,
  task_info as details
FROM    msdb.dbo.rds_fn_task_status(NULL, 0)
WHERE last_updated > DATEADD(hour, -24, GETDATE())
ORDER BY last_updated DESC;

