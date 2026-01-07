DECLARE @users TABLE (
  [db] [nvarchar](128) NULL,
  [usertype] [nvarchar](255) NOT NULL,
  [user] [nvarchar](255) NOT NULL,
  [principal_id] INT NOT NULL,
  [create_date] DATETIME NULL,
  [modify_date] DATETIME NULL
)

DECLARE @command VARCHAR(2000)
SELECT @command = 'USE ?;
SELECT
  DB_NAME() [db],
  p.type_desc [usertype],
  p.name [user],
  p.principal_id,
  p.create_date,
  p.modify_date
FROM sys.database_principals p
WHERE p.type = ''S''
  AND p.authentication_type = 0
  AND p.name NOT LIKE ''##%''
  AND p.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'')'
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
WHERE mp.type = ''S'' AND mp.authentication_type = 0'
INSERT INTO @roles EXEC sp_MSforeachdb @roles_command

DECLARE @serverid NVARCHAR(200) = @configId

SELECT
  @serverid + '/' + u.db + '/' + u.[user] AS [id],
  u.[user] AS [name],
  u.db AS [database],
  @serverid + '/' + u.db AS [database_id],
  u.usertype AS [type],
  u.create_date,
  u.modify_date,
  (SELECT r.role FROM @roles r WHERE r.db = u.db AND r.principal_id = u.principal_id FOR JSON PATH) AS [roles]
FROM @users u
ORDER BY u.db, u.[user]
