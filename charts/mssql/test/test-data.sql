-- Check if setup has already been run
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'TestDB')
BEGIN
    DECLARE @setupExists INT = 0;
    EXEC sp_executesql N'SELECT @exists = 1 FROM TestDB.dbo.sysobjects WHERE name = ''_SetupComplete'' AND xtype = ''U''',
        N'@exists INT OUTPUT', @setupExists OUTPUT;
    IF @setupExists = 1
    BEGIN
        PRINT 'Setup already complete, skipping.';
        RETURN;
    END;
END;

-- Create TestDB if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TestDB')
BEGIN
    CREATE DATABASE TestDB;
END;

-- Insert employee data first (before job tries to reference it)
IF NOT EXISTS (SELECT 1 FROM TestDB.dbo.sysobjects WHERE name = 'Employees' AND xtype = 'U')
BEGIN
    EXEC('
        CREATE TABLE TestDB.dbo.Employees (
            EmployeeID INT PRIMARY KEY,
            FirstName NVARCHAR(50),
            LastName NVARCHAR(50),
            BirthDate DATE,
            HireDate DATE,
            Position NVARCHAR(100)
        )
    ');
END;

-- Insert employee data
IF NOT EXISTS (SELECT 1 FROM TestDB.dbo.Employees WHERE EmployeeID = 1)
BEGIN
    INSERT INTO TestDB.dbo.Employees (EmployeeID, FirstName, LastName, BirthDate, HireDate, Position) VALUES
    (1, 'John', 'Doe', '1980-01-15', '2010-06-01', 'Software Engineer'),
    (2, 'Jane', 'Smith', '1985-03-22', '2012-09-15', 'Project Manager'),
    (3, 'Michael', 'Johnson', '1978-07-30', '2008-11-20', 'Database Administrator'),
    (4, 'Emily', 'Davis', '1990-12-05', '2015-04-10', 'Business Analyst'),
    (5, 'William', 'Brown', '1982-05-18', '2011-02-25', 'System Architect');
END;

-- Create EmployeeLogins table if not exists (with auto-increment ID for repeated inserts)
IF NOT EXISTS (SELECT 1 FROM TestDB.dbo.sysobjects WHERE name = 'EmployeeLogins' AND xtype = 'U')
BEGIN
    EXEC('
        CREATE TABLE TestDB.dbo.EmployeeLogins (
            LoginID INT IDENTITY(1,1) PRIMARY KEY,
            EmployeeID INT,
            LoginTime DATETIME,
            LogoutTime DATETIME,
            FOREIGN KEY (EmployeeID) REFERENCES TestDB.dbo.Employees(EmployeeID)
        )
    ');
END;

-- Create server logins first
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'TestUser')
    CREATE LOGIN TestUser WITH PASSWORD = 'TestPassword123!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AdminUser')
    CREATE LOGIN AdminUser WITH PASSWORD = 'TestPassword123!';

-- Create additional server logins for testing
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ReportUser')
    CREATE LOGIN ReportUser WITH PASSWORD = 'TestPassword123!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AppServiceUser')
    CREATE LOGIN AppServiceUser WITH PASSWORD = 'TestPassword123!';

-- Create database users mapped to logins
EXEC TestDB.dbo.sp_executesql N'
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''TestUser'')
        CREATE USER TestUser FOR LOGIN TestUser;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''AdminUser'')
        CREATE USER AdminUser FOR LOGIN AdminUser;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''ReportUser'')
        CREATE USER ReportUser FOR LOGIN ReportUser;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''AppServiceUser'')
        CREATE USER AppServiceUser FOR LOGIN AppServiceUser;
    EXEC sp_addrolemember ''db_datareader'', ''TestUser'';
    EXEC sp_addrolemember ''db_datawriter'', ''AdminUser'';
    EXEC sp_addrolemember ''db_datareader'', ''ReportUser'';
    EXEC sp_addrolemember ''db_datareader'', ''AppServiceUser'';
    EXEC sp_addrolemember ''db_datawriter'', ''AppServiceUser'';
';

-- Create database-level users (without server logins)
EXEC TestDB.dbo.sp_executesql N'
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''DbOnlyReader'')
        CREATE USER DbOnlyReader WITHOUT LOGIN;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''DbOnlyWriter'')
        CREATE USER DbOnlyWriter WITHOUT LOGIN;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''DbOnlyAdmin'')
        CREATE USER DbOnlyAdmin WITHOUT LOGIN;
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''DbOnlyGuest'')
        CREATE USER DbOnlyGuest WITHOUT LOGIN;
    EXEC sp_addrolemember ''db_datareader'', ''DbOnlyReader'';
    EXEC sp_addrolemember ''db_datareader'', ''DbOnlyWriter'';
    EXEC sp_addrolemember ''db_datawriter'', ''DbOnlyWriter'';
    EXEC sp_addrolemember ''db_owner'', ''DbOnlyAdmin'';
';

-- Job creation in msdb
DECLARE @jobName NVARCHAR(128) = 'SampleJob';
DECLARE @scheduleName NVARCHAR(128) = 'SampleJob Schedule';
DECLARE @jobId UNIQUEIDENTIFIER;

-- Delete existing job if present (clean slate)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @jobName)
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = @jobName, @delete_unused_schedule = 1;
END;

-- Create a new job
EXEC msdb.dbo.sp_add_job
    @job_name = @jobName,
    @enabled = 1,
    @job_id = @jobId OUTPUT;

-- Add job step
DECLARE @sql VARCHAR(MAX) = '
PRINT ''Hello, this is a sample job step.'';
INSERT INTO TestDB.dbo.EmployeeLogins (EmployeeID, LoginTime, LogoutTime)
VALUES (1, GETDATE(), NULL);
';

EXEC msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = 'Sample Step',
    @subsystem = 'TSQL',
    @command = @sql,
    @retry_attempts = 0,
    @retry_interval = 0,
    @on_success_action = 1,
    @on_fail_action = 2;

-- Add job schedule to run every 10 seconds
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = @scheduleName,
    @freq_type = 4,
    @freq_subday_type = 2,
    @freq_subday_interval = 10,
    @freq_interval = 1;

EXEC msdb.dbo.sp_attach_schedule
    @job_name = @jobName,
    @schedule_name = @scheduleName;

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @jobName,
    @server_name = '(LOCAL)';

-- Start the job immediately
EXEC msdb.dbo.sp_start_job @job_name = @jobName;

-- Mark setup as complete
EXEC('CREATE TABLE TestDB.dbo._SetupComplete (CompletedAt DATETIME DEFAULT GETDATE())');
EXEC('INSERT INTO TestDB.dbo._SetupComplete DEFAULT VALUES');

PRINT 'Job created and started successfully!';
