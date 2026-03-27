DECLARE @dbName NVARCHAR(128) = '$(.config.name)';
DECLARE @dbUser NVARCHAR(128) = '$(.params.user.name)';
DECLARE @dbRole NVARCHAR(128) = '$(.params.role)';
DECLARE @serverName NVARCHAR(128);

DECLARE @retval nvarchar(500);
DECLARE @ParmDefinition nvarchar(500);
SET @ParmDefinition = N'@retvalOUT nvarchar(500) OUTPUT';
DECLARE @dbOutput TABLE (msg NVARCHAR(500))

SET @serverName = @@SERVERNAME;

IF CHARINDEX('\', @dbName) > 0
  SET @dbName = RIGHT(@dbName, CHARINDEX('\', REVERSE(@dbName)) - 1)

DECLARE @sql NVARCHAR(MAX);

BEGIN TRY

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @dbUser)
BEGIN
  DECLARE @errorMsg NVARCHAR(500) = 'Login ' + @dbUser + ' does not exist on server ' + @serverName + '. Create the login first.';
  RAISERROR(@errorMsg, 11, 1);
END

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @dbName)
BEGIN
  DECLARE @errorString NVARCHAR(255) = 'Database ' + @dbName + ' does not exist on this server ' + @serverName;
  RAISERROR(@errorString, 11, 1);
END

SET @sql = 'USE [' + @dbName + '];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @dbUser + ''')
  CREATE USER [' + @dbUser + '] FOR LOGIN [' + @dbUser + '];';
EXEC sp_executesql @sql;

SET @sql = 'USE [' + @dbName + '];
IF EXISTS (SELECT 1 FROM sys.database_role_members
  WHERE role_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = ''' + @dbRole + ''')
    AND member_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = ''' + @dbUser + '''))
BEGIN
  SELECT @retvalOUT = ''User ' + @dbUser + ' is already a member of ' + @dbRole + ' in database ' + @dbName + ' on server ' + @serverName + ''';
END
ELSE
BEGIN
  ALTER ROLE [' + @dbRole + '] ADD MEMBER [' + @dbUser + '];
  SELECT @retvalOUT = ''User ' + @dbUser + ' assigned to ' + @dbRole + ' role in database ' + @dbName + ' on server ' + @serverName + ''';
END;';

EXEC sp_executesql @sql, @ParmDefinition, @retvalOUT=@retval OUTPUT;
INSERT INTO @dbOutput VALUES (@retval);

END TRY
BEGIN CATCH
DECLARE @Message varchar(MAX) = ERROR_MESSAGE(),
  @Severity int = ERROR_SEVERITY(),
  @State smallint = ERROR_STATE()

RAISERROR(@Message, @Severity, @State)
END CATCH

select * from @dbOutput
