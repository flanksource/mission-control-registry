# mission-control-watchtower

![Version: 0.1.29-beta.9](https://img.shields.io/badge/Version-0.1.29--beta.9-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Mission Control Helm Chart for monitoring mission-control itself

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connectionName | string | `"mission-control-db"` |  |
| fullnameOverride | string | `""` |  |
| isAgent | bool | `false` |  |
| labels | object | `{}` |  |
| nameOverride | string | `""` |  |
| playbooks | bool | `true` |  |
| pushLocation.url | string | `""` |  |
| topology.enabled | bool | `true` |  |
| topologyName | string | `"mission-control"` |  |
| views.enabled | bool | `true` |  |
| views.pods.enabled | bool | `false` |  |
| views.pods.sidebar | bool | `false` |  |
| views.unhealthyConfigs.enabled | bool | `true` |  |
| views.unhealthyConfigs.sidebar | bool | `true` |  |

