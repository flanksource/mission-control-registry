{{ template "chart.header" . }}
{{ template "chart.deprecationWarning" . }}
{{ template "chart.description" . }}

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

{{ template "chart.valuesSection" . }}
{{ template "chart.maintainersSection" . }}
