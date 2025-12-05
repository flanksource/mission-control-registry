-- Create temp table for job steps
CREATE TABLE #JobSteps (
    job_id UNIQUEIDENTIFIER,
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
    proxy_id INT
);

-- Insert job step data using sp_help_jobstep for each job
DECLARE @job_id UNIQUEIDENTIFIER;
DECLARE job_cursor CURSOR FOR
    SELECT job_id FROM msdb.dbo.sysjobs WHERE enabled = 1;

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        INSERT INTO #JobSteps (step_id, step_name, subsystem, command, flags, cmdexec_success_code,
                              on_success_action, on_success_step_id, on_fail_action, on_fail_step_id,
                              server, database_name, database_user_name, retry_attempts, retry_interval,
                              os_run_priority, output_file_name, last_run_outcome, last_run_duration,
                              last_run_retries, last_run_date, last_run_time, proxy_id)
        EXEC msdb.dbo.sp_help_jobstep @job_id = @job_id;

        -- Update the job_id for all rows we just inserted
        UPDATE #JobSteps SET job_id = @job_id WHERE job_id IS NULL;
    END TRY
    BEGIN CATCH
        -- If sp_help_jobstep fails for this job, just skip it and continue
        PRINT 'Skipping job_id: ' + CAST(@job_id AS VARCHAR(50)) + ' - ' + ERROR_MESSAGE();
    END CATCH

    FETCH NEXT FROM job_cursor INTO @job_id;
END;

CLOSE job_cursor;
DEALLOCATE job_cursor;

WITH LastJobRuns AS (
    SELECT job_id, MAX(instance_id) AS last_instance_id
    FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
    WHERE step_id = 0
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
),
JobStepsAgg AS (
    SELECT
        js.job_id,
        STRING_AGG(js.command, CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10))
            WITHIN GROUP (ORDER BY js.step_id) as sql
    FROM #JobSteps js
    WHERE js.subsystem = 'TSQL'
    GROUP BY js.job_id
)
SELECT
    js.job_name,
    lower(CAST(js.job_id AS NVARCHAR(36))) as job_id,
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
    COALESCE(jst.sql, '') as sql
FROM JobStatus js
LEFT JOIN JobStepsAgg jst ON js.job_id = jst.job_id;

-- Clean up temp table
DROP TABLE #JobSteps;



