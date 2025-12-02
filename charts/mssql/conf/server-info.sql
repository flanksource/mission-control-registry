DECLARE @serverContainmentTable table
(
  name nvarchar(35),
  minimum int,
  maximum int,
  config_value int,
  run_value int
)
INSERT INTO @serverContainmentTable (name,minimum,maximum,config_value,run_value)
exec sp_configure 'contained database authentication'
DECLARE @serverContainment int
select top 1 @serverContainment = config_value from @serverContainmentTable

SELECT
  CONVERT(nvarchar(100), SERVERPROPERTY('ServerName')) AS [ServerName],
  SERVERPROPERTY('BuildClrVersion') AS [BuildClrVersion],
  SERVERPROPERTY('Collation') AS [Collation],
  SERVERPROPERTY('Edition') AS [Edition],
  SERVERPROPERTY('EngineEdition') AS [EngineEdition],
  SERVERPROPERTY('InstanceName') AS [InstanceName],
  SERVERPROPERTY('IsClustered') AS [IsClustered],
  SERVERPROPERTY('IsHadrEnabled') AS [IsHadrEnabled],
  SERVERPROPERTY('MachineName') AS [MachineName],
  SERVERPROPERTY('ProductVersion') AS [ProductVersion],
  SERVERPROPERTY('ProductLevel') AS [ProductLevel],
  SERVERPROPERTY('ProductMajorVersion') AS [ProductMajorVersion],
  SERVERPROPERTY('ProductMinorVersion') AS [ProductMinorVersion],
  @serverContainment AS [ContainedUsers],
  (
    SELECT
      a.name,
      a.type_desc AS [type],
      CASE WHEN a.is_state_enabled = 1 THEN 'true' ELSE 'false' END AS [enabled],
      a.queue_delay,
      a.on_failure_desc AS [on_failure],
      JSON_QUERY('[' + STRING_AGG('"' + d.audit_action_name + '"', ',') WITHIN GROUP (ORDER BY d.audit_action_name) + ']') AS [actions]
    FROM sys.server_audits a
    LEFT JOIN sys.server_audit_specifications s ON a.audit_guid = s.audit_guid
    LEFT JOIN sys.server_audit_specification_details d ON s.server_specification_id = d.server_specification_id
    GROUP BY a.audit_id, a.name, a.type_desc, a.is_state_enabled, a.queue_delay, a.on_failure_desc
    FOR JSON PATH
  ) AS [audits]
