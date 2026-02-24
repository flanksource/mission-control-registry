# mission-control-mssql

Flanksource Mission Control bundle for managing MSSQL servers and databases.

## Overview

This Helm chart deploys Flanksource Mission Control resources for monitoring and managing Microsoft SQL Server instances. It includes scrapers for configuration discovery, health checks for connectivity, and playbooks for common administrative tasks.

The bundle provides visibility into:
- Server and database configurations
- Login accounts and permissions
- SQL Agent job status
- Database backups stored in S3

## Prerequisites

- Flanksource Mission Control installed
- A running MSSQL Server instance
- Connection details provided as either:
  - `url` - Direct connection string (e.g., `sqlserver://sa:password@host:1433`)
  - `connectionName` - Reference to a Mission Control connection (e.g., `connection://namespace/name`)
- (Optional) For backup discovery: S3 bucket with `.bak` files and IAM role access
- (Optional) For "Create Login User" playbook: a configured email connection

## Quickstart

```bash
helm install mssql-bundle flanksource/mission-control-mssql \
  --namespace mission-control \
  --set url="sqlserver://sa:YourPassword@mssql-server:1433"
```

Or using a pre-existing connection:

```bash
helm install mssql-bundle flanksource/mission-control-mssql \
  --namespace mission-control \
  --set connectionName="connection://mission-control/mssql-creds"
```

## Config Items

The chart discovers the following configuration item types:

| Config Type | Description | Parent |
|-------------|-------------|--------|
| `MSSQL::Server` | Server properties: version, edition, clustering, HADR status, collation, audits | - |
| `MSSQL::Database` | Database settings: recovery model, compatibility level, encryption, files, users | `MSSQL::Server` |
| `MSSQL::Logon` | Login accounts with server roles, database roles, and group memberships | `MSSQL::Server` |
| `MSSQL::AgentJob` | SQL Agent jobs with last run status and duration | - |
| `MSSQL::DatabaseBackup` | `.bak` files discovered in S3 (optional, requires `backups.enabled`) | `MSSQL::Database` |

## Health Checks

A Canary resource performs a basic connectivity test against the MSSQL server on a configurable schedule (default: every 5 minutes).

## Playbooks

| Playbook | Target Config Type | Description |
|----------|-------------------|-------------|
| Run SQL | `MSSQL::Server`, `MSSQL::Database` | Execute arbitrary SQL with approval audit trail |
| Run Agent Job Now | `MSSQL::AgentJob` | Execute SQL Agent job T-SQL steps immediately |
| Grant DB Access | `MSSQL::Database` | Grant temporary read-only or read-write access with automatic expiration |
| Kill Long Running Transactions | `MSSQL::Server` | Identify and optionally kill transactions exceeding a time threshold |
| Create Login User | `MSSQL::Server` | Create a new SQL login and email credentials (requires `playbooks.createUser.enabled`) |
| Restore Tables from Backup | `MSSQL::Database` | Restore specific tables from an S3 backup via RDS native restore (requires `playbooks.restoreTables`) |

## Backup Discovery

When `backups.enabled` is set to `true`, the chart deploys a scraper that uses `boto3` to scan S3 buckets for `.bak` files. It extracts the database name from each filename using a configurable regex and creates `MSSQL::DatabaseBackup` config items linked to their parent `MSSQL::Database`.

Example configuration:

```yaml
backups:
  enabled: true
  schedule: "@every 4h"
  databaseRegex: '^(?P<database>.*)_\d*T\d*\.bak$'
  s3:
    - s3://my-bucket/backups/mssql/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| approvers | object | `{"people":[]}` | Playbook approvers configuration |
| approvers.people | list | `[]` | List of people who can approve playbook executions people: - admin |
| backups | object | `{"databaseRegex":"^(?P<database>.*)_\\d*T\\d*\\.bak$","enabled":false,"s3":[],"schedule":"@every 4h"}` | Backup scraper configuration for discovering .bak files in S3 |
| backups.databaseRegex | string | `"^(?P<database>.*)_\\d*T\\d*\\.bak$"` | Regex with named capture group 'database' to extract DB name from .bak filename Default: everything before the first underscore |
| backups.enabled | bool | `false` | Enable backup scraper |
| backups.s3 | list | `[]` | S3 URIs to scan for .bak files (s3://bucket/prefix format) |
| backups.schedule | string | `"@every 4h"` | Cron schedule for backup scraping |
| canary | object | `{"enabled":true,"schedule":"@every 5m"}` | Health check canary configuration |
| canary.enabled | bool | `true` | Enable health check canary |
| canary.schedule | string | `"@every 5m"` | Cron schedule for health checks |
| connectionName | string | `""` | Connection name for a connection:// reference (created externally) Use either connectionName OR url, not both |
| id | string | `"mssql"` | Logical ID of the database instance used to create an idempotent config-db ID that is consistent across restarts and db failovers |
| playbooks | object | `{"createUser":{"emailConnection":"","enabled":false},"enabled":true,"grantAccess":true,"killLongRunningTransactions":true,"restoreTables":false,"runAgentJob":true,"runSql":true}` | Playbook configuration |
| playbooks.createUser.emailConnection | string | `""` | Email connection reference for sending credentials (required when enabled) Example: "connection://default/smtp" or "connection://notifications/email" |
| playbooks.createUser.enabled | bool | `false` | Enable "Create Login User" playbook for creating new SQL logins |
| playbooks.enabled | bool | `true` | Enable all playbooks |
| playbooks.grantAccess | bool | `true` | Enable "Grant DB Access" playbook for granting temporary database access |
| playbooks.killLongRunningTransactions | bool | `true` | Enable "Kill Long Running Transactions" playbook |
| playbooks.restoreTables | bool | `false` | Enable "Restore Tables from Backup" playbook (requires backups.enabled) |
| playbooks.runAgentJob | bool | `true` | Enable "Run Agent Job Now" playbook for executing T-SQL steps from agent jobs |
| playbooks.runSql | bool | `true` | Enable "Run SQL" playbook for executing arbitrary SQL |
| rds | object | `{"tasks":false}` | AWS RDS specific configuration |
| rds.tasks | bool | `false` | Enable RDS task scraping (for AWS RDS SQL Server instances) |
| scrape | object | `{"databases":true,"incrementalSchedule":"@every 15m","jobs":true,"schedule":"@every 4h"}` | Scraper configuration for discovering MSSQL resources |
| scrape.databases | bool | `true` | Scrape database information |
| scrape.incrementalSchedule | string | `"@every 15m"` | Cron schedule for incremental scrape (changes only) |
| scrape.jobs | bool | `true` | Scrape SQL Agent jobs and their history |
| scrape.schedule | string | `"@every 4h"` | Cron schedule for full scrape |
| url | string | `""` | Direct connection string to the MSSQL server Example: "sqlserver://sa:YourStrong@Passw0rd@localhost:1433" |
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
