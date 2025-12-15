--
CREATE DATABASE IF NOT EXISTS TestDB;
GO

USE TestDB;
GO

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    BirthDate DATE,
    HireDate DATE,
    Position NVARCHAR(100)
);



CREATE TABLE EmployeeLogins (
    EmployeeID INT PRIMARY KEY,
    LoginTime DATETIME,
    LogoutTime DATETIME,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE USER TestUser  WITH PASSWORD = 'TestPassword123!';
CREATE USER AdminUser  WITH PASSWORD = 'TestPassword123!';

-- Add test user to datareader role and admin to datawriter role
EXEC sp_addrolemember 'db_datareader', 'TestUser';
EXEC sp_addrolemember 'db_datawriter', 'AdminUser';

-- Create SERVER Audit for login (to the DB) and Database audit for db connection
CREATE SERVER AUDIT [LoginAudit]
TO FILE (FILEPATH = 'C:\AuditLogs\', MAXSIZE = 10 MB, MAX_ROLLOVER_FILES = 5)
WITH (ON_FAILURE = CONTINUE);

CREATE SERVER AUDIT SPECIFICATION [LoginAuditSpec]
FOR SERVER AUDIT [LoginAudit]
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP);

CREATE DATABASE AUDIT SPECIFICATION [DBConnectionAudit]
FOR SERVER AUDIT [LoginAudit]
ADD (DATABASE_LOGON);

-- creates a job step that uses Transact-SQL


USE msdb;

DECLARE @name varchar(max) = 'SampleJob';



-- Declare job variables
DECLARE @jobName NVARCHAR(128) =  @name;
DECLARE @scheduleName NVARCHAR(128) =  + @name + ' Schedule';
DECLARE @jobId UNIQUEIDENTIFIER;

-- Check if the job already exists
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @jobName)
BEGIN
    SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE name = @jobName;

    PRINT 'Updating the existing job...';
    EXEC sp_detach_schedule @job_name = @jobName, @schedule_name = @scheduleName;
    EXEC sp_delete_schedule @schedule_name = @scheduleName;
    EXEC dbo.sp_delete_jobstep @job_name=@jobName, @step_id = 1;
END
ELSE
BEGIN
    -- Create a new job
    PRINT 'Creating a new job...';

    EXEC sp_add_job
        @job_name = @jobName,
        @enabled = 1,
        @job_id = @jobId OUTPUT;
END;


-- Create a SQL command to insert dummy records into EmployeeLogin table
DECLARE @sql VARCHAR(MAX) = N'
PRINT ''Hello, this is a sample job step.'';
INSERT INTO TestDB.dbo.EmployeeLogins (EmployeeID, LoginTime, LogoutTime)
VALUES (1, GETDATE(), NULL);
';



-- Add job steps (example of a T-SQL job step)
EXEC sp_add_jobstep
    @job_id = @jobId,
    @step_name = 'Sample Step',
    @subsystem = 'TSQL',
    @command = @sql,
    @retry_attempts = 0,
    @retry_interval = 0,
    @on_success_action = 1, -- Quit the job reporting success
    @on_fail_action = 2; -- Quit the job reporting failure

-- Add job schedule to run every minute
EXEC sp_add_schedule
    @schedule_name = @scheduleName,
    @freq_type = 4, -- 4 = Daily
    @freq_subday_type = 4, -- 4 = Minutes
    @freq_subday_interval = 1, -- Every 1 minute
    @freq_interval = 1; -- Every 1 hour


EXEC sp_attach_schedule
	@job_name=@jobName,
	@schedule_name=@scheduleName

EXEC sp_update_job
	@job_id=@jobId,
	@enabled=1;


-- Start the job if you want to run it immediately
-- EXEC sp_start_job @job_name = @jobName;

PRINT 'Job created or updated successfully!';



INSERT INTO Employees (EmployeeID, FirstName, LastName, BirthDate, HireDate, Position) VALUES
(1, 'John', 'Doe', '1980-01-15', '2010-06-01', 'Software Engineer'),
(2, 'Jane', 'Smith', '1985-03-22', '2012-09-15', 'Project Manager'),
(3, 'Michael', 'Johnson', '1978-07-30', '2008-11-20', 'Database Administrator'),
(4, 'Emily', 'Davis', '1990-12-05', '2015-04-10', 'Business Analyst'),
(5, 'William', 'Brown', '1982-05-18', '2011-02-25', 'System Architect');
