# mission-control-argocd

![Version: 0.1.11](https://img.shields.io/badge/Version-0.1.11-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for the ArgoCD bundle for Flanksource Mission Control

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| argocd | object | `{"baseURL":"","connection":"","namespace":"argocd","token":{"value":""}}` | ArgoCD API configuration used by canary checks @schema type: object additionalProperties: false @schema |
| argocd.baseURL | string | `""` | ArgoCD API base URL (e.g. https://argocd.example.com) |
| argocd.connection | string | `""` | Optional connection reference for ArgoCD API checks (e.g. connection://http/argocd) |
| argocd.namespace | string | `"argocd"` | Deprecated: Use namespace instead @schema default: argocd deprecated: true @schema |
| argocd.token | object | `{"value":""}` | Bearer token for ArgoCD API authentication. This is an EnvVar object — either a static value or a reference to a Kubernetes secret.  Static value:   token:     value: "Bearer eyJhbGciOiJIUzI1NiIs..."  From a Kubernetes secret:   token:     valueFrom:       secretKeyRef:         name: argocd-credentials         key: token  The value must include the "Bearer " prefix. @schema $ref: https://raw.githubusercontent.com/flanksource/duty/main/schema/openapi/scrape_config.schema.json#/$defs/EnvVar @schema |
| canary | object | `{"clusters":{"enabled":true},"enabled":false,"repositories":{"enabled":true},"schedule":"@every 5m"}` | Health check canary that verifies ArgoCD repositories and clusters via the API |
| canary.clusters | object | `{"enabled":true}` | Cluster health checks |
| canary.clusters.enabled | bool | `true` | Enable cluster health checking |
| canary.enabled | bool | `false` | Enable ArgoCD health check canary |
| canary.repositories | object | `{"enabled":true}` | Repository health checks |
| canary.repositories.enabled | bool | `true` | Enable repository health checking |
| canary.schedule | string | `"@every 5m"` | Cron schedule for health checks @schema default: "@every 5m" @schema |
| fullnameOverride | string | `""` |  |
| labels | object | `{}` |  |
| nameOverride | string | `""` |  |
| namespace | string | `"argocd"` | ArgoCD namespace where the ArgoCD pods are running @schema default: argocd @schema |
| topologyName | string | `"argocd"` | Deprecated: no longer used (topology removed) @schema default: argocd deprecated: true @schema |

