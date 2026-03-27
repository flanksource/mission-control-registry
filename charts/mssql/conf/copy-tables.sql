DECLARE @targetDb NVARCHAR(128) = '$(.config.name)';
DECLARE @tempDb NVARCHAR(128) = '$( getAction "Restore Backup to Temp DB" | .result.rows | jq ".[0].tempDb" )';
DECLARE @tables NVARCHAR(MAX) = '$(.params.tables)';
DECLARE @tableName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);
DECLARE @output TABLE (msg NVARCHAR(MAX));

IF @tempDb IS NULL OR DB_ID(@tempDb) IS NULL
BEGIN
  RAISERROR('Temp restore database [%s] not found', 16, 1, @tempDb);
  SELECT * FROM @output;
  RETURN;
END

INSERT INTO @output VALUES ('Copying tables from ' + QUOTENAME(@tempDb) + ' to ' + QUOTENAME(@targetDb));

DECLARE table_cursor CURSOR FOR
  SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@tables, ',')
  WHERE LTRIM(RTRIM(value)) != '';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
  -- Validate table name is a proper identifier (reject names that could break QUOTENAME)
  IF @tableName IS NULL OR @tableName = '' OR QUOTENAME(@tableName) IS NULL
  BEGIN
    INSERT INTO @output VALUES ('ERROR: Invalid table name: ' + ISNULL(@tableName, 'NULL'));
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
    RAISERROR('Invalid table name supplied', 16, 1);
    SELECT * FROM @output;
    RETURN;
  END

  BEGIN TRY
    -- Verify table exists in source
    SET @sql = 'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@tempDb) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @tbl) RAISERROR(''Table %s not found in restored database'', 16, 1, @tbl)';
    EXEC sp_executesql @sql, N'@tbl NVARCHAR(128)', @tbl = @tableName;

    -- Truncate and copy inside a transaction so truncate is rolled back if the insert fails
    BEGIN TRANSACTION;

    -- Truncate target table
    SET @sql = 'TRUNCATE TABLE ' + QUOTENAME(@targetDb) + '.dbo.' + QUOTENAME(@tableName);
    EXEC sp_executesql @sql;
    INSERT INTO @output VALUES ('Truncated ' + QUOTENAME(@targetDb) + '.dbo.' + QUOTENAME(@tableName));

    -- Copy data (SELECT * assumes identical schemas between source and target;
    -- ensure the restored backup matches the target schema version)
    SET @sql = 'INSERT INTO ' + QUOTENAME(@targetDb) + '.dbo.' + QUOTENAME(@tableName) + ' SELECT * FROM ' + QUOTENAME(@tempDb) + '.dbo.' + QUOTENAME(@tableName);
    EXEC sp_executesql @sql;
    INSERT INTO @output VALUES ('Copied data to ' + QUOTENAME(@targetDb) + '.dbo.' + QUOTENAME(@tableName));

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
      ROLLBACK TRANSACTION;
    DECLARE @errMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    INSERT INTO @output VALUES ('ERROR copying ' + QUOTENAME(@tableName) + ': ' + @errMsg);
    -- Clean up temp DB on failure
    CLOSE table_cursor;
    DEALLOCATE table_cursor;
    IF DB_ID(@tempDb) IS NOT NULL
    BEGIN
      SET @sql = 'DROP DATABASE ' + QUOTENAME(@tempDb);
      EXEC sp_executesql @sql;
      INSERT INTO @output VALUES ('Cleaned up temp database ' + QUOTENAME(@tempDb));
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
