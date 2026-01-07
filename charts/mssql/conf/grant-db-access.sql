DECLARE @dbName NVARCHAR(128) = '{{`{{(json ((.params.database).config )).id}}`}}';
DECLARE @dbUser NVARCHAR(128) = '{{`{{.params.user}}`}}';
DECLARE @dbRole NVARCHAR(128) = '';
DECLARE @accessType NVARCHAR(128) = '{{`{{.params.access}}`}}';
DECLARE @serverName NVARCHAR(128);

DECLARE @retval nvarchar(500);
DECLARE @ParmDefinition nvarchar(500);
SET @ParmDefinition = N'@retvalOUT nvarchar(500) OUTPUT';
DECLARE @dbOutput TABLE (msg NVARCHAR(500))

SET @serverName = @@SERVERNAME;

IF CHARINDEX('\', @dbName) > 0
  SET @dbName = RIGHT(@dbName, CHARINDEX('\', REVERSE(@dbName)) - 1)

DECLARE @sql NVARCHAR(MAX);
DECLARE @dbRoles TABLE (dbRole NVARCHAR(100))

IF @accessType = 'ReadWrite'
  INSERT INTO @dbRoles
  VALUES ('db_datareader'),
  ('db_datawriter')
ELSE
  INSERT INTO @dbRoles
  VALUES ('db_datareader')

DECLARE @CursorTestID INT;
BEGIN TRY
DECLARE ROLE_CURSOR SCROLL CURSOR FOR SELECT dbRole FROM @dbRoles

SET @sql = 'USE [' + @dbName + '];
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @dbUser
+ ''')
BEGIN
IF EXISTS (SELECT * FROM sys.database_role_members
WHERE role_principal_id in (SELECT principal_id
    FROM sys.database_principals WHERE name in (''db_owner'',
    ''db_securityadmin'',''db_accessadmin'',''db_backupoperator'',
    ''db_ddladmin'',''db_denydatawriter'',''db_denydatareader''))
    AND member_principal_id = (SELECT principal_id
      FROM sys.database_principals
      WHERE name = ''' + @dbUser + '''))
BEGIN
RAISERROR (''User ' + @dbUser + ' is already a member of of other built in db roles'
+ ' role in database ' + @dbName + ' on server ' + @serverName + CHAR(10)
+ ' i.e. user must not be in these roles for access to be granted db_owner,'
+ 'db_securityadmin,db_accessadmin,db_backupoperator,'
+ 'db_ddladmin,db_denydatawriter,db_denydatareader'',11,1);
END
END
ELSE
BEGIN
RAISERROR ('' User ' + @dbUser + ' does not exist or is invalid in database ' + @dbName + ' on server '
+ @serverName + ''',11,1)
END ;';
EXEC sp_executesql @sql;

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @dbName)
BEGIN
OPEN ROLE_CURSOR
FETCH NEXT FROM ROLE_CURSOR
INTO @dbRole
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql
    = 'USE [' + @dbName
    + '];
      IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @dbUser
    + ''')
  BEGIN
  IF EXISTS (SELECT 1 FROM sys.database_role_members
    WHERE role_principal_id = (SELECT principal_id
      FROM sys.database_principals WHERE name = ''' + @dbRole
    + ''')
      AND member_principal_id = (SELECT principal_id
          FROM sys.database_principals
          WHERE name = ''' + @dbUser
    + '''))
  BEGIN
    RAISERROR (''User ' + @dbUser + ' is already a member of ' + @dbRole
    + ' role in database ' + @dbName + ' on server ' + @serverName
    + ''',11,1);
  END
  END
  ELSE
  BEGIN
  RAISERROR ('' User ' + @dbUser + ' does not exist or is invalid in database ' + @dbName
    + ' on server ' + @serverName + ''',11,1)
  END ;';
  EXEC sp_executesql @sql;
  FETCH NEXT FROM ROLE_CURSOR
  INTO @dbRole
END
FETCH FIRST FROM ROLE_CURSOR
INTO @dbRole;

WHILE @@FETCH_STATUS = 0
BEGIN

  SET @sql
    = 'USE [' + @dbName + '];
      ALTER ROLE ' + @dbRole + ' ADD MEMBER [' + @dbUser + '];
      SELECT @retvalOUT = ''User ' + @dbUser + ' assigned to ' + @dbRole + ' role in database ' + @dbName
        + ' on server ' + @serverName + ''';';

  EXEC sp_executesql @sql, @ParmDefinition, @retvalOUT=@retval OUTPUT;
  INSERT INTO @dbOutput VALUES (@retval);
  FETCH NEXT FROM ROLE_CURSOR
  INTO @dbRole
END
END
ELSE
BEGIN

DECLARE @errorString NVARCHAR(255);
SET @errorString = 'Database ' + @dbName + ' does not exist on this server ' + @serverName;

RAISERROR(@errorString, 11, 1);
END
END TRY
BEGIN CATCH
DECLARE @Message varchar(MAX) = ERROR_MESSAGE(),
  @Severity int = ERROR_SEVERITY(),
  @State smallint = ERROR_STATE()

RAISERROR(@Message, @Severity, @State)
END CATCH

IF CURSOR_STATUS('global', 'ROLE_CURSOR') > 0
BEGIN
CLOSE ROLE_CURSOR
END
IF CURSOR_STATUS('global', 'ROLE_CURSOR') >= -1
BEGIN
DEALLOCATE ROLE_CURSOR
END
select * from @dbOutput
