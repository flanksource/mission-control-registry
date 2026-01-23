DECLARE @serverid NVARCHAR(200) = @configId

-- Table to collect database roles from all databases
DECLARE @database_roles TABLE (
  [DB] [nvarchar](128) NULL,
  [login_name] [nvarchar](255) NULL,
  [principal_sid] [varbinary](85) NULL,
  [role] [nvarchar](255) NOT NULL
)

-- Command to collect database roles using recursive CTE for nested roles
DECLARE @roles_command VARCHAR(2000)
SELECT @roles_command = 'USE ?;
WITH RoleMembers (member_principal_id, role_principal_id)
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
SELECT DISTINCT
  DB_NAME() [DB],
  mp.name [login_name],
  mp.sid [principal_sid],
  roles.name AS [role]
FROM RoleMembers drm
  JOIN sys.database_principals mp ON drm.member_principal_id = mp.principal_id
  JOIN sys.database_principals roles ON drm.role_principal_id = roles.principal_id
WHERE mp.type IN (''U'',''S'',''G'')
  AND mp.name NOT LIKE ''##%'''

INSERT INTO @database_roles EXEC sp_MSforeachdb @roles_command

SELECT
  @serverid + '/' + sp.name AS [id],
  sp.name AS [name],
  sp.type_desc AS [type],
  sp.is_disabled,
  sp.create_date,
  sp.modify_date,
  sp.default_database_name,
  sp.default_language_name,
  (
    SELECT
      srm.role_principal_id,
      sr.name AS [role],
      sr.type_desc AS [role_type],
      CASE WHEN sr.is_fixed_role = 1 THEN 'Fixed Server Role'
           WHEN sr.type_desc = 'WINDOWS_GROUP' THEN 'Windows Group'
           WHEN sr.type_desc = 'SERVER_ROLE' THEN 'Custom Server Role'
           ELSE sr.type_desc
      END AS [membership_type]
    FROM sys.server_role_members srm
    JOIN sys.server_principals sr ON srm.role_principal_id = sr.principal_id
    WHERE srm.member_principal_id = sp.principal_id
    FOR JSON PATH
  ) AS [server_roles],
  (
    SELECT
      parent.name AS [parent_group],
      parent.type_desc AS [parent_type]
    FROM sys.server_role_members parent_membership
    JOIN sys.server_principals parent ON parent_membership.role_principal_id = parent.principal_id
    WHERE parent_membership.member_principal_id = sp.principal_id
      AND parent.type IN ('G', 'R')
    FOR JSON PATH
  ) AS [member_of_groups],
  (
    SELECT
      dr.DB AS [database_name],
      dr.role AS [role_name]
    FROM @database_roles dr
    WHERE (dr.login_name = sp.name OR dr.principal_sid = sp.sid)
    FOR JSON PATH
  ) AS [database_roles]
FROM sys.server_principals sp
WHERE sp.type IN ('S', 'U', 'G', 'R', 'A')
  AND sp.name NOT LIKE '##%'
  AND sp.is_disabled = 0
ORDER BY sp.name
