DECLARE @threshold_seconds INT = {{.params.threshold}};
DECLARE @session_id INT;
DECLARE @killed_count INT = 0;

DECLARE session_cursor CURSOR FOR
SELECT r.session_id
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
WHERE r.session_id != @@SPID
  AND s.is_user_process = 1
  AND DATEDIFF(SECOND, r.start_time, GETDATE()) > @threshold_seconds;

OPEN session_cursor;
FETCH NEXT FROM session_cursor INTO @session_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        KILL @session_id;
        SET @killed_count = @killed_count + 1;
    END TRY
    BEGIN CATCH
        PRINT 'Failed to kill session ' + CAST(@session_id AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
    END CATCH
    FETCH NEXT FROM session_cursor INTO @session_id;
END

CLOSE session_cursor;
DEALLOCATE session_cursor;

SELECT @killed_count AS sessions_killed;
