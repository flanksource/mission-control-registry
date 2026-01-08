DECLARE @serverid NVARCHAR(200) = @configId

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
    SELECT srm.role_principal_id, sr.name AS [role]
    FROM sys.server_role_members srm
    JOIN sys.server_principals sr ON srm.role_principal_id = sr.principal_id
    WHERE srm.member_principal_id = sp.principal_id
    FOR JSON PATH
  ) AS [roles]
FROM sys.server_principals sp
WHERE sp.type IN ('S', 'U', 'G')
  AND sp.name NOT LIKE '##%'
  AND sp.is_disabled = 0
ORDER BY sp.name
