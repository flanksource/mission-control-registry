CREATE TABLE #job_steps (
    step_id INT,
    step_name NVARCHAR(128),
    subsystem NVARCHAR(40),
    command NVARCHAR(MAX),
    flags INT,
    cmdexec_success_code INT,
    on_success_action TINYINT,
    on_success_step_id INT,
    on_fail_action TINYINT,
    on_fail_step_id INT,
    server NVARCHAR(128),
    database_name NVARCHAR(128),
    database_user_name NVARCHAR(128),
    retry_attempts INT,
    retry_interval INT,
    os_run_priority INT,
    output_file_name NVARCHAR(200),
    last_run_outcome INT,
    last_run_duration INT,
    last_run_retries INT,
    last_run_date INT,
    last_run_time INT,
    proxy_id INT,
    job_id UNIQUEIDENTIFIER
);

DECLARE @job_id UNIQUEIDENTIFIER;
DECLARE @job_name NVARCHAR(128);

DECLARE job_cursor CURSOR FOR
SELECT job_id, name FROM msdb.dbo.sysjobs WHERE enabled = 1;

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_id, @job_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        INSERT INTO #job_steps (step_id, step_name, subsystem, command, flags, cmdexec_success_code,
            on_success_action, on_success_step_id, on_fail_action, on_fail_step_id, server,
            database_name, database_user_name, retry_attempts, retry_interval, os_run_priority,
            output_file_name, last_run_outcome, last_run_duration, last_run_retries, last_run_date, last_run_time, proxy_id)
        EXEC msdb.dbo.sp_help_jobstep @job_id = @job_id;

        UPDATE #job_steps SET job_id = @job_id WHERE job_id IS NULL;
    END TRY
    BEGIN CATCH
    END CATCH

    FETCH NEXT FROM job_cursor INTO @job_id, @job_name;
END

CLOSE job_cursor;
DEALLOCATE job_cursor;

WITH LastJobRuns AS (
    SELECT job_id, MAX(instance_id) AS last_instance_id
    FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
    WHERE step_id != 0
    GROUP BY job_id
),
JobStatus AS (
    SELECT
        j.job_id,
        j.name AS job_name,
        h.run_status,
        h.message AS job_message,
        CONVERT(DATETIME,
            CONVERT(VARCHAR(8), h.run_date) + ' ' +
            STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), h.run_time), 6), 3, 0, ':'), 6, 0, ':')
        ) as run_datetime,
        STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), h.run_duration), 6), 3, 0, ':'), 6, 0, ':') as duration_formatted,
        (h.run_duration / 10000) * 3600 + ((h.run_duration % 10000) / 100) * 60 + (h.run_duration % 100) AS duration_seconds
    FROM msdb.dbo.sysjobs j WITH (NOLOCK)
    LEFT JOIN LastJobRuns l ON j.job_id = l.job_id
    LEFT JOIN msdb.dbo.sysjobhistory h WITH (NOLOCK) ON h.job_id = l.job_id AND h.instance_id = l.last_instance_id
    WHERE j.enabled = 1
)
SELECT
    js.job_name,
    CASE
        WHEN js.run_status = 0 THEN 'Failed'
        WHEN js.run_status = 1 THEN 'Succeeded'
        WHEN js.run_status = 2 THEN 'Retry'
        WHEN js.run_status = 3 THEN 'Canceled'
        WHEN js.run_status = 4 THEN 'In Progress'
        ELSE 'Unknown'
    END as status,
    js.run_datetime,
    js.duration_formatted as duration,
    js.duration_seconds,
    js.job_message,
    CASE WHEN js.run_status = 0 THEN 1 ELSE 0 END as is_failed,
    (
        SELECT step_id, step_name, subsystem, command, database_name,
               CASE on_success_action
                   WHEN 1 THEN 'Quit with success'
                   WHEN 2 THEN 'Quit with failure'
                   WHEN 3 THEN 'Go to next step'
                   WHEN 4 THEN 'Go to step ' + CAST(on_success_step_id AS VARCHAR(10))
                   ELSE 'Unknown'
               END as on_success_action,
               CASE on_fail_action
                   WHEN 1 THEN 'Quit with success'
                   WHEN 2 THEN 'Quit with failure'
                   WHEN 3 THEN 'Go to next step'
                   WHEN 4 THEN 'Go to step ' + CAST(on_fail_step_id AS VARCHAR(10))
                   ELSE 'Unknown'
               END as on_fail_action,
               retry_attempts, retry_interval
        FROM #job_steps s
        WHERE s.job_id = js.job_id
        ORDER BY s.step_id
        FOR JSON PATH
    ) as steps
FROM JobStatus js
WHERE job_name != 'syspolicy_purge_history'
ORDER BY js.run_datetime DESC;

DROP TABLE #job_steps;
