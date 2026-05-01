DECLARE @threshold_seconds INT = CAST($(.params.threshold) AS INT);
DECLARE @session_id INT;

-- Snapshot of sessions about to be killed, returned at the end as the audit trail.
DECLARE @victims TABLE (
    kind                VARCHAR(20),
    session_id          INT,
    start_time          DATETIME,
    duration_seconds    INT,
    status              NVARCHAR(60),
    login_name          NVARCHAR(256),
    host_name           NVARCHAR(256),
    program_name        NVARCHAR(256),
    database_name       NVARCHAR(256),
    query_text          NVARCHAR(MAX),
    kill_status         NVARCHAR(256)
);

INSERT INTO @victims (kind, session_id, start_time, duration_seconds, status, login_name, host_name, program_name, database_name, query_text, kill_status)
SELECT
    'request',
    r.session_id,
    r.start_time,
    DATEDIFF(SECOND, r.start_time, GETDATE()),
    r.status,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(r.database_id),
    t.text,
    NULL
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id != @@SPID
  AND s.is_user_process = 1
  AND r.status <> 'rollback'
  AND DATEDIFF(SECOND, r.start_time, GETDATE()) > @threshold_seconds;

INSERT INTO @victims (kind, session_id, start_time, duration_seconds, status, login_name, host_name, program_name, database_name, query_text, kill_status)
SELECT
    'idle_open_tx',
    s.session_id,
    at.transaction_begin_time,
    DATEDIFF(SECOND, at.transaction_begin_time, GETDATE()),
    s.status,
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(s.database_id),
    lq.text,
    NULL
FROM sys.dm_tran_session_transactions st
JOIN sys.dm_tran_active_transactions at ON st.transaction_id = at.transaction_id
JOIN sys.dm_exec_sessions s              ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_connections c      ON c.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) lq
WHERE s.is_user_process = 1
  AND s.session_id != @@SPID
  AND NOT EXISTS (
        SELECT 1 FROM sys.dm_exec_requests r
        WHERE r.session_id = s.session_id AND r.status = 'rollback'
  )
  AND DATEDIFF(SECOND, at.transaction_begin_time, GETDATE()) > @threshold_seconds;

DECLARE victim_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT session_id FROM @victims;

OPEN victim_cursor;
FETCH NEXT FROM victim_cursor INTO @session_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC ('KILL ' + CAST(@session_id AS VARCHAR(10)));
        UPDATE @victims SET kill_status = 'killed' WHERE session_id = @session_id;
    END TRY
    BEGIN CATCH
        UPDATE @victims
        SET kill_status = 'failed: ' + ERROR_MESSAGE()
        WHERE session_id = @session_id;
    END CATCH
    FETCH NEXT FROM victim_cursor INTO @session_id;
END

CLOSE victim_cursor;
DEALLOCATE victim_cursor;

SELECT * FROM @victims ORDER BY duration_seconds DESC;
