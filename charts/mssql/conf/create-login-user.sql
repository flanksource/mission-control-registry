-- ABOUTME: Creates a new SQL Server login with a randomly generated password

DECLARE @serverName NVARCHAR(128) = @@SERVERNAME;
DECLARE @sql NVARCHAR(MAX);

BEGIN TRY
  -- Check if login already exists
  IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @username)
  BEGIN
    RAISERROR('Login %s already exists on server %s', 11, 1, @username, @serverName);
  END
  ELSE
  BEGIN
    -- Create the login
    SET @sql = 'CREATE LOGIN [' + @username + '] WITH PASSWORD = ''' + @password + ''', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sp_executesql @sql;

    -- Return the credentials
    SELECT
      @serverName AS [server],
      @username AS [username],
      'Login created successfully' AS [status];
  END
END TRY
BEGIN CATCH
  DECLARE @Message VARCHAR(MAX) = ERROR_MESSAGE(),
    @Severity INT = ERROR_SEVERITY(),
    @State SMALLINT = ERROR_STATE();

  RAISERROR(@Message, @Severity, @State);
END CATCH
