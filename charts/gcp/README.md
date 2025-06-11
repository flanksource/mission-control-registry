# mission-control-gcp

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for the GCP bundle on Flanksource Mission Control

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connection | string | `""` |  |
| credentials.value | string | `""` |  |
| credentials.valueFrom.configMapKeyRef.key | string | `""` |  |
| credentials.valueFrom.configMapKeyRef.name | string | `""` |  |
| credentials.valueFrom.helmRef.key | string | `""` |  |
| credentials.valueFrom.helmRef.name | string | `""` |  |
| credentials.valueFrom.secretKeyRef.key | string | `""` |  |
| credentials.valueFrom.secretKeyRef.name | string | `""` |  |
| credentials.valueFrom.serviceAccount | string | `""` |  |
| endpoint | string | `""` |  |
| exclude | list | `[]` |  |
| include | list | `[]` |  |
| labels | object | `{}` |  |
| project | string | `""` |  |
| scraper.name | string | `"gcp"` |  |
| skipTLSVerify | bool | `false` |  |
| transform | object | `{}` |  |

