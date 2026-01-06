# MSSQL Mission Control Bundle

A Helm chart for monitoring and managing Microsoft SQL Server instances with [Flanksource Mission Control](https://docs.flanksource.com/).

## Features

### Health Checks
- Connection health canary with configurable schedule

### Config Discovery
Automatically discovers and catalogs:
- **MSSQL::Server** - Server configuration and properties
- **MSSQL::Database** - Database details, size, and configuration
- **MSSQL::AgentJob** - SQL Agent jobs with step definitions

### Change Tracking
- SQL Agent job execution history
- RDS task status (for AWS RDS SQL Server)

### Playbooks

| Playbook | Description |
|----------|-------------|
| **Run SQL** | Execute arbitrary SQL statements with approval workflow |
| **Grant DB Access** | Grant temporary read/write access to databases with auto-expiry |
| **Kill Long Running Transactions** | List and optionally terminate queries exceeding threshold |
| **Run Agent Job Now** | Execute T-SQL steps from SQL Agent jobs immediately |

## Installation

```bash
helm repo add flanksource https://flanksource.github.io/charts
helm install mssql flanksource/mission-control-mssql \
  --set connectionName=my-sql-server \
  --set approvers.people[0]=admin
```

## Configuration

### Connection

Specify either a connection reference or direct URL:

```yaml
# Option 1: Connection reference (recommended)
connectionName: my-sql-server

# Option 2: Direct connection string
url: "sqlserver://user:password@hostname:1433"
```

# Permissions
The scraper needs the following permission to fully list agent jobs
```sql
 USE msdb;
EXEC sp_addrolemember
  @rolename = 'SQLAgentOperatorRole',
  @membername = 'LOGIN NAME';
```


### Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `id` | Logical ID for config-db | `mssql` |
| `connectionName` | Connection reference name | `sql-server` |
| `url` | Direct connection string | `""` |
| `playbooks.enabled` | Master switch to enable/disable all playbooks | `true` |
| `playbooks.runSql` | Enable Run SQL playbook | `true` |
| `playbooks.runAgentJob` | Enable Run Agent Job playbook | `true` |
| `playbooks.grantAccess` | Enable Grant Access playbook | `true` |
| `playbooks.killLongRunningTransactions` | Enable Kill Transactions playbook | `true` |
| `canary.enabled` | Enable health check canary | `true` |
| `canary.schedule` | Health check schedule | `@every 5m` |
| `scrape.schedule` | Full scrape schedule | `@every 4h` |
| `scrape.incrementalSchedule` | Incremental scrape schedule | `@every 15m` |
| `scrape.databases` | Scrape database info | `true` |
| `scrape.jobs` | Scrape SQL Agent jobs | `true` |
| `rds.tasks` | Scrape RDS tasks (AWS) | `false` |
| `approvers.people` | List of approver usernames | `[]` |
| `approvers.teams` | List of approver teams | `[]` |

## Disabling Features

### Disable all playbooks
```yaml
playbooks:
  enabled: false
```

### Disable specific playbook
```yaml
playbooks:
  enabled: true
  runSql: false  # Disable only Run SQL playbook
```

### Disable scraping
```yaml
scrape:
  databases: false
  jobs: false
```

## Requirements

- Flanksource Mission Control
- SQL Server connection with appropriate permissions:
  - `VIEW SERVER STATE` for server info
  - `VIEW DATABASE STATE` for database info
  - `SQLAgentReaderRole` in msdb for agent jobs
  - `db_owner` or appropriate roles for playbook actions

## AWS RDS SQL Server

For AWS RDS SQL Server instances, enable RDS task scraping:

```yaml
rds:
  tasks: true
```

This tracks backup, restore, and other RDS-specific tasks as changes.
