# mission-control-misc-playbooks

A Helm chart for miscellaneous Mission Control playbooks (kubectl, web requests)

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| enabled | bool | `true` |  |
| labels | object | `{}` |  |
| playbooks.enabled | bool | `true` |  |
| playbooks.kubectl | bool | `true` | create a playbook to run arbitrary kubectl commands against a Kubernetes cluster |
| playbooks.webRequest | bool | `true` | create a playbook to make arbitrary HTTP web requests |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
