DECLARE @targetDb NVARCHAR(128) = '{{.config.name}}';
DECLARE @tempDb NVARCHAR(128);
DECLARE @output TABLE (msg NVARCHAR(MAX));

SELECT TOP 1 @tempDb = name
FROM sys.databases
WHERE name LIKE @targetDb + '_restore_%'
ORDER BY create_date DESC;

IF @tempDb IS NOT NULL AND DB_ID(@tempDb) IS NOT NULL
BEGIN
  EXEC('ALTER DATABASE [' + @tempDb + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE');
  EXEC('DROP DATABASE [' + @tempDb + ']');
  INSERT INTO @output VALUES ('Dropped temp database [' + @tempDb + ']');
END
ELSE
BEGIN
  INSERT INTO @output VALUES ('No temp restore database found to clean up');
END

SELECT * FROM @output;
