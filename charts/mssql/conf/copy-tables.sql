DECLARE @targetDb NVARCHAR(128) = '{{.config.name}}';
DECLARE @tempDb NVARCHAR(128);
DECLARE @tables NVARCHAR(MAX) = '{{.params.tables}}';
DECLARE @tableName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);
DECLARE @output TABLE (msg NVARCHAR(MAX));

-- Find the temp restore DB (most recent _restore_ DB for this target)
SELECT TOP 1 @tempDb = name
FROM sys.databases
WHERE name LIKE @targetDb + '_restore_%'
ORDER BY create_date DESC;

IF @tempDb IS NULL
BEGIN
  RAISERROR('No restore database found matching pattern %s_restore_*', 16, 1, @targetDb);
  SELECT * FROM @output;
  RETURN;
END

INSERT INTO @output VALUES ('Copying tables from [' + @tempDb + '] to [' + @targetDb + ']');

DECLARE table_cursor CURSOR FOR
  SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@tables, ',')
  WHERE LTRIM(RTRIM(value)) != '';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    -- Verify table exists in source
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM [' + @tempDb + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''' + @tableName + ''') RAISERROR(''Table ' + @tableName + ' not found in restored database'', 16, 1)';
    EXEC sp_executesql @sql;

    -- Truncate target table
    SET @sql = 'TRUNCATE TABLE [' + @targetDb + '].dbo.[' + @tableName + ']';
    EXEC sp_executesql @sql;
    INSERT INTO @output VALUES ('Truncated [' + @targetDb + '].dbo.[' + @tableName + ']');

    -- Copy data
    SET @sql = 'INSERT INTO [' + @targetDb + '].dbo.[' + @tableName + '] SELECT * FROM [' + @tempDb + '].dbo.[' + @tableName + ']';
    EXEC sp_executesql @sql;
    INSERT INTO @output VALUES ('Copied data to [' + @targetDb + '].dbo.[' + @tableName + ']');
  END TRY
  BEGIN CATCH
    DECLARE @errMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    INSERT INTO @output VALUES ('ERROR copying [' + @tableName + ']: ' + @errMsg);
    -- Clean up temp DB on failure
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
    IF DB_ID(@tempDb) IS NOT NULL
    BEGIN
      EXEC('DROP DATABASE [' + @tempDb + ']');
      INSERT INTO @output VALUES ('Cleaned up temp database [' + @tempDb + ']');
    END
    RAISERROR('Failed to copy table %s: %s', 16, 1, @tableName, @errMsg);
    SELECT * FROM @output;
    RETURN;
  END CATCH

  FETCH NEXT FROM table_cursor INTO @tableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

INSERT INTO @output VALUES ('All tables copied successfully');
SELECT * FROM @output;
