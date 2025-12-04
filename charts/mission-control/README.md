# mission-control-watchtower

![Version: 0.1.32](https://img.shields.io/badge/Version-0.1.32-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Mission Control Helm Chart for monitoring mission-control itself

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connectionName | string | `"mission-control-db"` |  |
| createConnection | bool | `true` |  |
| fullnameOverride | string | `""` |  |
| global.prometheus.connection | string | `""` |  |
| isAgent | bool | `false` |  |
| labels | object | `{}` |  |
| nameOverride | string | `""` |  |
| playbooks | bool | `true` |  |
| prometheusURL | string | `""` |  |
| pushLocation.url | string | `""` |  |
| topology.enabled | bool | `true` |  |
| topologyName | string | `"mission-control"` |  |
| views.dashboard.enabled | bool | `true` |  |
| views.dashboard.sidebar | bool | `true` |  |
| views.enabled | bool | `true` |  |
| views.failingHealthChecks.enabled | bool | `true` |  |
| views.failingHealthChecks.sidebar | bool | `false` |  |
| views.job_histories.enabled | bool | `true` |  |
| views.job_histories.sidebar | bool | `false` |  |
| views.notificationSendHistory.enabled | bool | `true` |  |
| views.notificationSendHistory.sidebar | bool | `false` |  |
| views.pods.enabled | bool | `true` |  |
| views.pods.sidebar | bool | `false` |  |
| views.recentChanges.enabled | bool | `true` |  |
| views.recentChanges.sidebar | bool | `false` |  |
| views.system.enabled | bool | `true` |  |
| views.system.sidebar | bool | `true` |  |
| views.unhealthyConfigs.enabled | bool | `true` |  |
| views.unhealthyConfigs.sidebar | bool | `false` |  |

