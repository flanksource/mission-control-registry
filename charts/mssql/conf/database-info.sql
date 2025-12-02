DECLARE @mytable TABLE (
    [DB] [nvarchar](128) NULL,
  [containment] INT NULL,
  [status] [nvarchar](60) NULL,
    [usertype] [nvarchar](255) NOT NULL,
    [login] [nvarchar] (255) NOT NULL,
    [user] [nvarchar] (255) NOT NULL,
  [id] INT NOT NULL
)

DECLARE @dbfiles TABLE (
  [DB] [nvarchar](128) NULL,
  [file_type] [nvarchar](10) NULL,
  [name] [nvarchar](128) NULL,
  [physical_name] [nvarchar](260) NULL,
  [size_mb] DECIMAL(18,2) NULL,
  [max_size_mb] DECIMAL(18,2) NULL,
  [growth] [nvarchar](50) NULL,
  [state] [nvarchar](60) NULL
)

DECLARE @dbconfig TABLE (
  [DB] [nvarchar](128) NULL,
  [recovery_model] [nvarchar](60) NULL,
  [compatibility_level] INT NULL,
  [collation] [nvarchar](128) NULL,
  [is_auto_close_on] BIT NULL,
  [is_auto_shrink_on] BIT NULL,
  [is_auto_create_stats_on] BIT NULL,
  [is_auto_update_stats_on] BIT NULL,
  [is_read_only] BIT NULL,
  [is_encrypted] BIT NULL,
  [snapshot_isolation] [nvarchar](60) NULL,
  [is_read_committed_snapshot_on] BIT NULL,
  [page_verify] [nvarchar](60) NULL
)

DECLARE @dbaudit TABLE (
  [DB] [nvarchar](128) NULL,
  [name] [nvarchar](128) NULL,
  [enabled] BIT NULL
)

DECLARE @dbaudit_actions TABLE (
  [DB] [nvarchar](128) NULL,
  [audit_name] [nvarchar](128) NULL,
  [action] [nvarchar](128) NULL
)

DECLARE @command VARCHAR(2000)
SELECT @command = 'USE ?; SELECT D.name [db],D.containment,D.state_desc [status],''CONTAINED '' + p.type_desc [usertype],
CASE WHEN p.type in (''U'',''G'') THEN SUSER_SNAME(p.sid) ELSE '''' END [login],p.name [user], p.principal_id
FROM	SYS.DATABASES D JOIN
    (SELECT DB_NAME() [DB]) C ON D.NAME = C.DB LEFT JOIN
    (	SELECT DB_NAME() DB,l.sid [lsid],p.*
      from sys.database_Principals p left join sys.syslogins l on p.sid = l.sid and
        l.hasaccess = 1 and p.type in (''U'',''S'',''G'') and p.name not like ''##%''
    ) p on  D.NAME = p.DB COLLATE SQL_Latin1_General_CP1_CI_AS
where D.containment = 1 and lsid is null and authentication_type in (2,3)
union
SELECT D.name [db],D.containment,D.state_desc [status],p.type_desc [usertype],
p.loginname [login],p.name [user], p.principal_id
FROM	SYS.DATABASES D JOIN
    (SELECT DB_NAME() [DB]) C ON D.NAME = C.DB LEFT JOIN
    (	SELECT DB_NAME() DB,l.sid [lsid],CASE WHEN l.name = p.name
      COLLATE Latin1_General_CI_AS THEN '''' ELSE l.name END [login],l.name [loginname],p.*
      from sys.database_Principals p left join sys.syslogins l
      on p.sid = l.sid and l.hasaccess = 1 and p.type in (''U'',''S'',''G'')
      and p.name not like ''##%''
    ) p on  D.NAME = p.DB COLLATE SQL_Latin1_General_CP1_CI_AS
where lsid is not null  and authentication_type in (1,3)'
INSERT INTO @mytable EXEC sp_MSforeachdb @command

declare @roles table (
  [DB] [nvarchar](128) NULL,
  [id] INT NULL,
  [role] [nvarchar](255) NOT NULL
)
DECLARE @roles_command varchar(2000)

SELECT @roles_command = 'USE ?; WITH RoleMembers (member_principal_id, role_principal_id)
AS
(
  SELECT
  rm1.member_principal_id,
  rm1.role_principal_id
  FROM sys.database_role_members rm1 (NOLOCK)
  UNION ALL
  SELECT
  d.member_principal_id,
  rm.role_principal_id
  FROM sys.database_role_members rm (NOLOCK)
  INNER JOIN RoleMembers AS d
  ON rm.member_principal_id = d.role_principal_id
)
select distinct DB_NAME() [DB], mp.principal_id, roles.name as [role]
from RoleMembers drm
  join sys.database_principals mp on (drm.member_principal_id = mp.principal_id)
  join sys.database_principals roles on (drm.role_principal_id = roles.principal_id)
  left join sys.syslogins sl on mp.sid = sl.sid
where mp.type in (''U'',''S'',''G'')'
insert into @roles EXEC sp_MSforeachdb @roles_command

-- Populate database files (data and log)
INSERT INTO @dbfiles
SELECT
  d.name [DB],
  CASE f.type WHEN 0 THEN 'DATA' WHEN 1 THEN 'LOG' ELSE 'OTHER' END [file_type],
  f.name,
  f.physical_name,
  CAST(f.size * 8.0 / 1024 AS DECIMAL(18,2)) [size_mb],
  CASE WHEN f.max_size = -1 THEN -1 ELSE CAST(f.max_size * 8.0 / 1024 AS DECIMAL(18,2)) END [max_size_mb],
  CASE WHEN f.is_percent_growth = 1 THEN CAST(f.growth AS VARCHAR) + '%'
       ELSE CAST(f.growth * 8 / 1024 AS VARCHAR) + 'MB' END [growth],
  f.state_desc [state]
FROM sys.master_files f
JOIN sys.databases d ON f.database_id = d.database_id

-- Populate database configuration
INSERT INTO @dbconfig
SELECT
  name [DB],
  recovery_model_desc,
  compatibility_level,
  collation_name,
  is_auto_close_on,
  is_auto_shrink_on,
  is_auto_create_stats_on,
  is_auto_update_stats_on,
  is_read_only,
  is_encrypted,
  snapshot_isolation_state_desc,
  is_read_committed_snapshot_on,
  page_verify_option_desc
FROM sys.databases

-- Populate audit specifications
DECLARE @audit_command VARCHAR(2000)
SELECT @audit_command = 'USE ?;
IF EXISTS (SELECT 1 FROM sys.database_audit_specifications)
SELECT DISTINCT DB_NAME() [DB], a.name, a.is_state_enabled [enabled]
FROM sys.database_audit_specifications a'
INSERT INTO @dbaudit EXEC sp_MSforeachdb @audit_command

DECLARE @audit_actions_command VARCHAR(2000)
SELECT @audit_actions_command = 'USE ?;
IF EXISTS (SELECT 1 FROM sys.database_audit_specifications)
SELECT DB_NAME() [DB], a.name [audit_name], s.audit_action_name [action]
FROM sys.database_audit_specifications a
JOIN sys.database_audit_specification_details s ON a.database_specification_id = s.database_specification_id'
INSERT INTO @dbaudit_actions EXEC sp_MSforeachdb @audit_actions_command

DECLARE @serverid nvarchar(200) = @configId

SELECT
  @serverid AS [serverid],
  @serverid + '/' + d.name AS [id],
  d.name AS [name],
  d.state_desc AS [status],
  d.containment AS [iscontained],
  cfg.recovery_model,
  cfg.compatibility_level,
  cfg.collation,
  cfg.is_auto_close_on,
  cfg.is_auto_shrink_on,
  cfg.is_auto_create_stats_on,
  cfg.is_auto_update_stats_on,
  cfg.is_read_only,
  cfg.is_encrypted,
  cfg.snapshot_isolation,
  cfg.is_read_committed_snapshot_on,
  cfg.page_verify,
  (SELECT file_type, name, physical_name, size_mb, max_size_mb, growth, state
   FROM @dbfiles f WHERE f.DB = d.name FOR JSON PATH) AS [files],
  (SELECT DISTINCT u.[user], u.[login], u.usertype,
    (SELECT r.role FROM @roles r WHERE r.DB = u.DB AND r.id = u.id FOR JSON PATH) AS [roles]
   FROM @mytable u WHERE u.DB = d.name FOR JSON PATH) AS [users],
  (SELECT a.name, a.enabled,
    JSON_QUERY('[' + STRING_AGG('"' + act.action + '"', ',') WITHIN GROUP (ORDER BY act.action) + ']') AS [actions]
   FROM @dbaudit a
   LEFT JOIN @dbaudit_actions act ON act.DB = a.DB AND act.audit_name = a.name
   WHERE a.DB = d.name
   GROUP BY a.DB, a.name, a.enabled
   FOR JSON PATH) AS [audits]
FROM sys.databases d
LEFT JOIN @dbconfig cfg ON d.name = cfg.DB
ORDER BY d.name
