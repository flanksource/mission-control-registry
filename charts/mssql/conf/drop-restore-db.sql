DECLARE @tempDb NVARCHAR(128) = '$( getAction "Restore Backup to Temp DB" | .result.rows | jq ".[0].tempDb" )';
DECLARE @output TABLE (msg NVARCHAR(MAX));

IF @tempDb IS NOT NULL AND DB_ID(@tempDb) IS NOT NULL
BEGIN
  EXEC('ALTER DATABASE ' + QUOTENAME(@tempDb) + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE');
  EXEC('DROP DATABASE ' + QUOTENAME(@tempDb));
  INSERT INTO @output VALUES ('Dropped temp database ' + QUOTENAME(@tempDb));
END
ELSE
BEGIN
  INSERT INTO @output VALUES ('No temp restore database found to clean up');
END

SELECT * FROM @output;
