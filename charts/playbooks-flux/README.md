# mission-control-playbooks-flux

A Helm chart for Flux Playbooks for Flanksource Mission Control.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| createPullRequest | bool | `true` |  |
| git.connection | string | `nil` |  |
| git.type | string | `"github"` |  |
| git.url | string | `nil` |  |
| playbooks.createDeployment | bool | `true` |  |
| playbooks.createHelmRelease | bool | `true` |  |
| playbooks.debug | bool | `false` |  |
| playbooks.edit | bool | `true` |  |
| playbooks.enabled | bool | `true` |  |
| playbooks.reconcile | bool | `true` |  |
| playbooks.requestNamespaceAccess | bool | `true` |  |
| playbooks.resume | bool | `true` |  |
| playbooks.scale | bool | `true` |  |
| playbooks.suspend | bool | `true` |  |
| playbooks.updateHelmChartVersion | bool | `true` |  |
| playbooks.updateHelmValues | bool | `true` |  |
| playbooks.updateImage | bool | `true` |  |
| playbooks.updateResources | bool | `true` |  |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
