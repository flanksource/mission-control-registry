CREATE TABLE #job_steps (
    step_id INT, step_name NVARCHAR(128), subsystem NVARCHAR(40),
    command NVARCHAR(MAX), flags INT, cmdexec_success_code INT,
    on_success_action TINYINT, on_success_step_id INT,
    on_fail_action TINYINT, on_fail_step_id INT, server NVARCHAR(128),
    database_name NVARCHAR(128), database_user_name NVARCHAR(128),
    retry_attempts INT, retry_interval INT, os_run_priority INT,
    output_file_name NVARCHAR(200), last_run_outcome INT,
    last_run_duration INT, last_run_retries INT,
    last_run_date INT, last_run_time INT, proxy_id INT
);

DECLARE @job_id UNIQUEIDENTIFIER;
SELECT @job_id = job_id FROM msdb.dbo.sysjobs WHERE name = '{{.config.name}}';

IF @job_id IS NOT NULL
BEGIN
    INSERT INTO #job_steps
    EXEC msdb.dbo.sp_help_jobstep @job_id = @job_id;
END

SELECT
    step_id,
    step_name,
    database_name,
    CASE
        WHEN database_name IS NOT NULL AND database_name != ''
        THEN 'USE [' + database_name + ']; ' + command
        ELSE command
    END as sql
FROM #job_steps
WHERE subsystem = 'TSQL'
ORDER BY step_id;

DROP TABLE #job_steps;
