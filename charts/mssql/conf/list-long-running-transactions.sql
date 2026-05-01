DECLARE @threshold_seconds INT = CAST($(.params.threshold) AS INT);

-- Active requests running longer than the threshold.
SELECT
    'request'                                                AS kind,
    r.session_id,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE())                AS duration_seconds,
    r.status,
    r.command,
    r.wait_type,
    r.wait_resource,
    r.blocking_session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(r.database_id)                                   AS database_name,
    t.text                                                   AS query_text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id != @@SPID
  AND s.is_user_process = 1
  AND DATEDIFF(SECOND, r.start_time, GETDATE()) > @threshold_seconds

UNION ALL

-- Idle sessions with an open transaction older than the threshold.
-- These are the classic blocker / deadlock culprits that don't show up in dm_exec_requests.
SELECT
    'idle_open_tx'                                           AS kind,
    s.session_id,
    at.transaction_begin_time                                AS start_time,
    DATEDIFF(SECOND, at.transaction_begin_time, GETDATE())   AS duration_seconds,
    s.status,
    NULL                                                     AS command,
    NULL                                                     AS wait_type,
    NULL                                                     AS wait_resource,
    NULL                                                     AS blocking_session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(s.database_id)                                   AS database_name,
    lq.text                                                  AS query_text
FROM sys.dm_tran_session_transactions st
JOIN sys.dm_tran_active_transactions at ON st.transaction_id = at.transaction_id
JOIN sys.dm_exec_sessions s              ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_connections c      ON c.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) lq
WHERE s.is_user_process = 1
  AND s.session_id != @@SPID
  AND NOT EXISTS (
        SELECT 1 FROM sys.dm_exec_requests r WHERE r.session_id = s.session_id
  )
  AND DATEDIFF(SECOND, at.transaction_begin_time, GETDATE()) > @threshold_seconds

ORDER BY duration_seconds DESC;
