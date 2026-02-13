DECLARE @targetDb NVARCHAR(128) = '{{.config.name}}';
DECLARE @s3Key NVARCHAR(500) = '{{(json ((.params.backup).config)).config.s3_key}}';
DECLARE @tempDb NVARCHAR(128) = @targetDb + '_restore_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
DECLARE @s3Arn NVARCHAR(500);
DECLARE @taskId INT;
DECLARE @lifecycle NVARCHAR(50);
DECLARE @taskInfo NVARCHAR(MAX);
DECLARE @pollCount INT = 0;
DECLARE @maxPolls INT = 180; -- 30 minutes at 10s intervals
DECLARE @output TABLE (msg NVARCHAR(MAX));

-- Convert s3://bucket/key to arn:aws:s3:::bucket/key
SET @s3Arn = 'arn:aws:s3:::' + SUBSTRING(@s3Key, 6, LEN(@s3Key) - 5);

INSERT INTO @output VALUES ('Restoring ' + @s3Arn + ' to temp database [' + @tempDb + ']');

EXEC msdb.dbo.rds_restore_database
  @restore_db_name = @tempDb,
  @s3_arn_to_restore_from = @s3Arn;

-- Get the task ID for our restore
SELECT TOP 1 @taskId = task_id
FROM msdb.dbo.rds_fn_task_status(NULL, 0)
WHERE db_name = @tempDb
ORDER BY task_id DESC;

IF @taskId IS NULL
BEGIN
  RAISERROR('Failed to find RDS restore task for database %s', 16, 1, @tempDb);
  SELECT * FROM @output;
  RETURN;
END

INSERT INTO @output VALUES ('RDS task ID: ' + CAST(@taskId AS NVARCHAR(20)));

-- Poll for completion
WHILE @pollCount < @maxPolls
BEGIN
  SELECT @lifecycle = lifecycle, @taskInfo = task_info
  FROM msdb.dbo.rds_fn_task_status(NULL, @taskId);

  IF @lifecycle = 'SUCCESS'
  BEGIN
    INSERT INTO @output VALUES ('Restore completed successfully');
    BREAK;
  END

  IF @lifecycle IN ('ERROR', 'CANCELLED')
  BEGIN
    INSERT INTO @output VALUES ('Restore failed: ' + ISNULL(@taskInfo, 'unknown error'));
    -- Clean up temp DB if it exists
    IF DB_ID(@tempDb) IS NOT NULL
    BEGIN
      EXEC('DROP DATABASE [' + @tempDb + ']');
      INSERT INTO @output VALUES ('Cleaned up temp database [' + @tempDb + ']');
    END
    RAISERROR('RDS restore task failed: %s', 16, 1, @taskInfo);
    SELECT * FROM @output;
    RETURN;
  END

  SET @pollCount = @pollCount + 1;
  WAITFOR DELAY '00:00:10';
END

IF @pollCount >= @maxPolls
BEGIN
  INSERT INTO @output VALUES ('Restore timed out after 30 minutes');
  IF DB_ID(@tempDb) IS NOT NULL
  BEGIN
    EXEC('DROP DATABASE [' + @tempDb + ']');
    INSERT INTO @output VALUES ('Cleaned up temp database [' + @tempDb + ']');
  END
  RAISERROR('RDS restore timed out after 30 minutes', 16, 1);
  SELECT * FROM @output;
  RETURN;
END

SELECT * FROM @output;
