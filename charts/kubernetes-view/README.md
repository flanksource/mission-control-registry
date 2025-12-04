# mission-control-kubernetes-view

![Version: 0.1.31](https://img.shields.io/badge/Version-0.1.31-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for Kubernetes views in Flanksource Mission Control

## Maintainers

| Name        | Email | Url |
| ----------- | ----- | --- |
| Flanksource |       |     |

## Values

| Key                                  | Type   | Default | Description |
| ------------------------------------ | ------ | ------- | ----------- |
| enabled                              | bool   | `true`  |             |
| global.prometheus.connection         | string | `""`    |             |
| labels                               | object | `{}`    |             |
| views.clusterOverview.enabled        | bool   | `true`  |             |
| views.clusterOverview.sidebar        | bool   | `true`  |             |
| views.deployments.enabled            | bool   | `true`  |             |
| views.deployments.sidebar            | bool   | `true`  |             |
| views.enabled                        | bool   | `true`  |             |
| views.helmReleases.enabled           | bool   | `true`  |             |
| views.helmReleases.sidebar           | bool   | `true`  |             |
| views.ingress.enabled                | bool   | `true`  |             |
| views.ingress.sidebar                | bool   | `true`  |             |
| views.namespace.deployments.enabled  | bool   | `true`  |             |
| views.namespace.enabled              | bool   | `true`  |             |
| views.namespace.helmReleases.enabled | bool   | `true`  |             |
| views.namespace.ingress.enabled      | bool   | `true`  |             |
| views.nodes.enabled                  | bool   | `true`  |             |
| views.nodes.sidebar                  | bool   | `true`  |             |
| views.pod.enabled                    | bool   | `true`  |             |
| views.pods.enabled                   | bool   | `true`  |             |
| views.pods.sidebar                   | bool   | `true`  |             |
