DECLARE @users TABLE (
  [db] [nvarchar](128) NULL,
  [containment] INT NULL,
  [usertype] [nvarchar](255) NOT NULL,
  [login] [nvarchar](255) NOT NULL,
  [user] [nvarchar](255) NOT NULL,
  [principal_id] INT NOT NULL,
  [authentication_type] INT NULL
)

DECLARE @command VARCHAR(2000)
SELECT @command = 'USE ?;
SELECT
  DB_NAME() [db],
  D.containment,
  CASE WHEN D.containment = 1 AND l.sid IS NULL THEN ''CONTAINED '' + p.type_desc ELSE p.type_desc END [usertype],
  CASE WHEN p.type IN (''U'',''G'') THEN ISNULL(SUSER_SNAME(p.sid), '''') ELSE ISNULL(l.name, '''') END [login],
  p.name [user],
  p.principal_id,
  p.authentication_type
FROM sys.databases D
JOIN (SELECT DB_NAME() [DB]) C ON D.name = C.DB
JOIN sys.database_principals p ON 1=1
LEFT JOIN sys.syslogins l ON p.sid = l.sid AND l.hasaccess = 1
WHERE D.name = DB_NAME()
  AND p.type IN (''U'',''S'',''G'')
  AND p.name NOT LIKE ''##%''
  AND p.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'')
  AND (
    (D.containment = 1 AND l.sid IS NULL AND p.authentication_type IN (2,3))
    OR (l.sid IS NOT NULL AND p.authentication_type IN (1,3))
  )'
INSERT INTO @users EXEC sp_MSforeachdb @command

DECLARE @roles TABLE (
  [db] [nvarchar](128) NULL,
  [principal_id] INT NULL,
  [role] [nvarchar](255) NOT NULL
)

DECLARE @roles_command VARCHAR(2000)
SELECT @roles_command = 'USE ?;
WITH RoleMembers (member_principal_id, role_principal_id) AS (
  SELECT rm1.member_principal_id, rm1.role_principal_id
  FROM sys.database_role_members rm1 (NOLOCK)
  UNION ALL
  SELECT d.member_principal_id, rm.role_principal_id
  FROM sys.database_role_members rm (NOLOCK)
  INNER JOIN RoleMembers AS d ON rm.member_principal_id = d.role_principal_id
)
SELECT DISTINCT
  DB_NAME() [db],
  mp.principal_id,
  roles.name AS [role]
FROM RoleMembers drm
JOIN sys.database_principals mp ON drm.member_principal_id = mp.principal_id
JOIN sys.database_principals roles ON drm.role_principal_id = roles.principal_id
WHERE mp.type IN (''U'',''S'',''G'')'
INSERT INTO @roles EXEC sp_MSforeachdb @roles_command

DECLARE @serverid NVARCHAR(200) = @configId

SELECT
  @serverid + '/' + u.db + '/' + u.[user] AS [id],
  u.[user] AS [name],
  u.db AS [database],
  @serverid + '/' + u.db AS [database_id],
  u.[login],
  u.usertype AS [type],
  u.containment AS [is_contained],
  u.authentication_type,
  (SELECT r.role FROM @roles r WHERE r.db = u.db AND r.principal_id = u.principal_id FOR JSON PATH) AS [roles]
FROM @users u
ORDER BY u.db, u.[user]
