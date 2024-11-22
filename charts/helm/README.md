# mission-control-helm

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for the Helm bundle of Flanksource Mission Control

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` |  |
| git.connection | string | `""` |  |
| git.type | string | `"github"` |  |
| git.url | string | `""` |  |
| labels | object | `{}` |  |
| nameOverride | string | `""` |  |
| playbook.enabled | bool | `true` |  |
| playbook.name | string | `"install-helm-chart"` |  |
| scraper.charts[0] | string | `"flanksource/mission-control-agent"` |  |
| scraper.charts[10] | string | `"flanksource/mission-control-prometheus"` |  |
| scraper.charts[11] | string | `"bitnami/postgresql"` |  |
| scraper.charts[12] | string | `"bitnami/postgresql-ha"` |  |
| scraper.charts[13] | string | `"bitnami/mysql"` |  |
| scraper.charts[14] | string | `"bitnami/rabbitmq"` |  |
| scraper.charts[15] | string | `"bitnami/kafka"` |  |
| scraper.charts[16] | string | `"bitnami/mongodb"` |  |
| scraper.charts[17] | string | `"bitnami/keycloak"` |  |
| scraper.charts[18] | string | `"bitnami/minio"` |  |
| scraper.charts[19] | string | `"bitnami/opensearch"` |  |
| scraper.charts[1] | string | `"flanksource/mission-control-argocd"` |  |
| scraper.charts[20] | string | `"bitnami/jaeger"` |  |
| scraper.charts[21] | string | `"bitnami/harbor"` |  |
| scraper.charts[22] | string | `"bitnami/memcached"` |  |
| scraper.charts[23] | string | `"bitnami/cert-manager"` |  |
| scraper.charts[24] | string | `"bitnami/external-secrets"` |  |
| scraper.charts[25] | string | `"bitnami/clickhouse"` |  |
| scraper.charts[26] | string | `"bitnami/jupyterhub"` |  |
| scraper.charts[27] | string | `"bitnami/grafana-operator"` |  |
| scraper.charts[28] | string | `"bitnami/argo-cd"` |  |
| scraper.charts[29] | string | `"bitnami/sonarqube"` |  |
| scraper.charts[2] | string | `"flanksource/mission-control-flux"` |  |
| scraper.charts[30] | string | `"bitnami/oauth2-proxy"` |  |
| scraper.charts[3] | string | `"flanksource/mission-control-aws"` |  |
| scraper.charts[4] | string | `"flanksource/mission-control-azure"` |  |
| scraper.charts[5] | string | `"flanksource/mission-control-flux"` |  |
| scraper.charts[6] | string | `"flanksource/mission-control-mongo-atlas"` |  |
| scraper.charts[7] | string | `"flanksource/mission-control-playbooks-flux"` |  |
| scraper.charts[8] | string | `"flanksource/mission-control-playbooks-kubernetes"` |  |
| scraper.charts[9] | string | `"flanksource/mission-control-postgres"` |  |
| scraper.name | string | `"helm-chart-scraper"` |  |
| scraper.schedule | string | `"@every 1d"` |  |

