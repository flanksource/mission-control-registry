# mission-control-playbooks-kubernetes

Flanksource Mission Control Playbooks that interact directly with the Kubernetes API

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| delete.types[0] | string | `"Kubernetes::Pod"` |  |
| delete.types[1] | string | `"Kubernetes::Deployment"` |  |
| delete.types[2] | string | `"Kubernetes::Statefulset"` |  |
| delete.types[3] | string | `"Kubernetes::ReplicaSet"` |  |
| delete.types[4] | string | `"Kubernetes::Job"` |  |
| delete.types[5] | string | `"Kubernetes::CronJob"` |  |
| delete.types[6] | string | `"Kubernetes::DaemonSet"` |  |
| delete.types[7] | string | `"Kubernetes::ConfigMap"` |  |
| playbooks.cleanupFailedPods | bool | `true` |  |
| playbooks.createDeployment | bool | `true` |  |
| playbooks.delete | bool | `true` |  |
| playbooks.deployHelmChart | bool | `true` |  |
| playbooks.enabled | bool | `true` |  |
| playbooks.ignoreChanges | bool | `true` |  |
| playbooks.logs | bool | `true` |  |
| playbooks.podSnapshot | bool | `false` |  |
| playbooks.requestNamespaceAccess | bool | `true` |  |
| playbooks.restart | bool | `true` |  |
| playbooks.scale | bool | `true` |  |
| playbooks.updateImage | bool | `true` |  |
| playbooks.updateResources | bool | `true` |  |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
