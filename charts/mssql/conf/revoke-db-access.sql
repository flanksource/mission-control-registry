DECLARE @dbName NVARCHAR(128) = '{{(json ((.params.database).config )).name}}';
DECLARE @dbUser NVARCHAR(128) = '{{(json ((.params.user).config )).name}}';
DECLARE @dbRole NVARCHAR(128) = '';
DECLARE @accessType NVARCHAR(128) = '{{.params.access}}';
DECLARE @serverName NVARCHAR(128);
SET @serverName = @@SERVERNAME;

DECLARE @retval nvarchar(500);
DECLARE @ParmDefinition nvarchar(500);
SET @ParmDefinition = N'@retvalOUT nvarchar(500) OUTPUT';
DECLARE @dbOutput TABLE (msg NVARCHAR(500))

SET @serverName = @@SERVERNAME;

SET @dbName = RIGHT(@dbName, CHARINDEX('\', REVERSE(@dbName)) - 1)

DECLARE @sql NVARCHAR(MAX);
DECLARE @dbRoles TABLE (dbRole NVARCHAR(100))

IF @accessType = 'ReadWrite'
    INSERT INTO @dbRoles    VALUES ('db_datareader'),    ('db_datawriter')
ELSE
    INSERT INTO @dbRoles    VALUES ('db_datareader')

DECLARE @CursorTestID INT;
BEGIN TRY
    DECLARE ROLE_CURSOR SCROLL CURSOR FOR SELECT dbRole FROM @dbRoles

    IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @dbName)
    BEGIN
        OPEN ROLE_CURSOR
        FETCH NEXT FROM ROLE_CURSOR
        INTO @dbRole
        WHILE @@FETCH_STATUS = 0
        BEGIN
      SET @sql
        = 'USE [' + @dbName + '];
          IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @dbUser + ''')
            BEGIN
              IF EXISTS (SELECT 1 FROM sys.database_role_members
                WHERE role_principal_id = (SELECT principal_id
                            FROM sys.database_principals WHERE name = ''' + @dbRole + ''')
                            AND member_principal_id = (SELECT principal_id
                                          FROM sys.database_principals
                                          WHERE name = ''' + @dbUser + '''))
              BEGIN
                ALTER ROLE ' + @dbRole + ' DROP MEMBER [' + @dbUser + '];
      SELECT @retvalOUT =  ''User ' + @dbUser + ' removed from ' + @dbRole + ' role in database ' + @dbName
                                + ' on server ' + @serverName + ''';
              END
    ELSE
    BEGIN
    SELECT @retvalOUT =  ''User '+@dbUser+' found but no role mapping to '+@dbRole+' role can be found in database '
    +@dbName+' on server '+@serverName+''';
    END
            END
            ELSE
            BEGIN
              RAISERROR ('' User ' + @dbUser + ' does not exist or is invalid in database ' + @dbName + ' on server '
              + @serverName + ''',11,1)
            END ;';
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
CLOSE ROLE_CURSOR
DEALLOCATE ROLE_CURSOR
select * from @dbOutput;
