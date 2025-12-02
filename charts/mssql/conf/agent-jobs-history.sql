SELECT
    j.name AS job_name,
    convert(varchar(200), j.job_id) + '/' + convert(varchar(200), h.instance_id) + '/' +  convert(varchar(200), h.step_id) as external_change_id,
    h.step_name as change_type,
    CASE
        WHEN h.run_status = 0 THEN 'Failed'
        WHEN h.run_status = 1 THEN 'Succeeded'
        WHEN h.run_status = 2 THEN 'Retry'
        WHEN h.run_status = 3 THEN 'Canceled'
        WHEN h.run_status = 4 THEN 'In Progress'
        ELSE 'Unknown'
    END as status,
    CONVERT(DATETIME,
        CONVERT(VARCHAR(8), h.run_date) + ' ' +
        STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), h.run_time), 6), 3, 0, ':'), 6, 0, ':')
    ) as created_at,
    STUFF(STUFF(RIGHT('000000' + CONVERT(VARCHAR(6), h.run_duration), 6), 3, 0, ':'), 6, 0, ':') as duration,
    (h.run_duration / 10000) * 3600 + ((h.run_duration % 10000) / 100) * 60 + (h.run_duration % 100) AS duration_seconds,
    h.retries_attempted,
    h.message
FROM msdb.dbo.sysjobhistory h WITH (NOLOCK)
JOIN msdb.dbo.sysjobs j WITH (NOLOCK) ON h.job_id = j.job_id
WHERE h.run_date >= CONVERT(INT, CONVERT(VARCHAR(8), DATEADD(day, -7, GETDATE()), 112))
AND j.name != 'syspolicy_purge_history'
AND (h.step_name != '(Job outcome)' )
ORDER BY h.instance_id DESC;
