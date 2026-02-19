# mission-control-misc-playbooks

A Helm chart for miscellaneous Mission Control playbooks (kubectl, curl)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `true` |  |
| labels | object | `{}` |  |
| playbooks.curl | bool | `true` | create a playbook to run arbitrary curl commands |
| playbooks.enabled | bool | `true` |  |
| playbooks.kubectl | bool | `true` | create a playbook to run arbitrary kubectl commands against a Kubernetes cluster |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
