# mission-control-kubernetes

A Helm chart for the Kubernetes bundle of Flanksource Mission Control

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterName | string | `""` |  |
| kubeconfig | object | `{}` |  |
| kubernetesConnection.cnrm | string | `nil` |  |
| kubernetesConnection.connection | string | `""` |  |
| kubernetesConnection.eks | string | `nil` |  |
| kubernetesConnection.gke | string | `nil` |  |
| kubernetesConnection.kubeconfig | string | `nil` |  |
| labels | object | `{}` |  |
| metrics.enabled | bool | `true` |  |
| metrics.queries | object | `{"gke":{"cluster_cpu":"1000 * sum(rate(kubernetes_io:container_cpu_core_usage_time{container_name!=\"\",cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}[5m]))","cluster_max_cpu":"1000 * sum(kubernetes_io:container_cpu_limit_cores{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}})","cluster_max_memory":"sum(kubernetes_io:container_memory_limit_bytes{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}})","cluster_memory":"sum(kubernetes_io:container_memory_used_bytes{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}})","cluster_name":"","namespace_cpu":"sum(rate(label_replace(kubernetes_io:container_cpu_core_usage_time{container_name!=\"\",cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}, \"namespace\",\"$1\",\"namespace_name\", \"(.+)\")[5m])) by (namespace)","namespace_memory":"sum(label_replace(kubernetes_io:container_memory_used_bytes{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}, \"namespace\",\"$1\",\"namespace_name\", \"(.+)\")) by (namespace)","node_cpu":"sum(rate(label_replace(kubernetes_io:node_cpu_core_usage_time{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}, \"node\",\"$1\",\"node_name\", \"(.+)\")[5m:])) by (node)","node_memory":"sum(label_replace(kubernetes_io:container_memory_used_bytes{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}, \"node\",\"$1\",\"node_name\", \"(.+)\")) by (node)","node_storage":"sum(label_replace(kubernetes_io:node_ephemeral_storage_used_bytes{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}},  \"node\",\"$1\",\"node_name\", \"(.+)\")) by (node)","pod_cpu":"sum(rate(label_replace(kubernetes_io:container_cpu_core_usage_time{container_name!=\"\",cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}, \"pod\",\"$1\",\"pod_name\", \"(.+)\")[5m:])) by (pod)","pod_memory":"sum(label_replace(kubernetes_io:container_memory_used_bytes{cluster_name=\"{{.Values.metrics.queries.gke.cluster_name}}\"{{.Values.prometheus.labels}}}, \"pod\",\"$1\",\"pod_name\", \"(.+)\")) by (pod)"},"prometheus":{"cluster_cpu":"1000 * sum(rate(container_cpu_usage_seconds_total{container!=\"\"{{.Values.prometheus.labels}}}[5m]))","cluster_max_cpu":"1000 * sum(kube_pod_container_resource_limits{resource=\"cpu\"{{.Values.prometheus.labels}}})","cluster_max_memory":"sum(kube_pod_container_resource_limits{resource=\"memory\"{{.Values.prometheus.labels}}})","cluster_memory":"sum(container_memory_working_set_bytes{container!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}})","namespace_cpu":"1000 * sum(rate(container_cpu_usage_seconds_total{container!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}}[5m])) by (namespace)","namespace_memory":"sum(container_memory_working_set_bytes{container!=\"\",pod!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}} * on(pod, namespace) group_left kube_pod_status_phase{phase=\"Running\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}} > 0) by (namespace)","node_cpu":"1000 * sum(rate(container_cpu_usage_seconds_total{container!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}}[5m])) by (node)","node_memory":"sum(container_memory_working_set_bytes{container!=\"\",pod!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}} * on(pod, namespace) group_left kube_pod_status_phase{phase=\"Running\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}} > 0) by (node)","node_storage":"max by (instance) (avg_over_time(node_filesystem_avail_bytes{mountpoint=\"/\",fstype!=\"rootfs\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}}[5m]))","pod_cpu":"1000 * sum(rate(container_cpu_usage_seconds_total{container!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}}[5m])) by (pod)","pod_memory":"sum(container_memory_working_set_bytes{container!=\"\"{{.Values.prometheus.labels | default .Values.prometheusLabels}}}) by (pod)"}}` | queries to retrieve cpu/memory metrics for cluster/node/pod |
| metrics.type | string | `"prometheus"` |  |
| playbooks | object | `{}` |  |
| prometheus.auth | object | `{}` |  |
| prometheus.connection | string | `"prometheus"` |  |
| prometheus.createConnection | bool | `true` |  |
| prometheus.labels | string | `""` |  |
| prometheus.url | object | `{}` |  |
| scraper.defaultExclusions.kind[0] | string | `"Secret"` |  |
| scraper.defaultExclusions.kind[10] | string | `"componentstatuses"` |  |
| scraper.defaultExclusions.kind[11] | string | `"controllerrevisions"` |  |
| scraper.defaultExclusions.kind[12] | string | `"certificaterequests"` |  |
| scraper.defaultExclusions.kind[13] | string | `"orders.acme.cert-manager.io"` |  |
| scraper.defaultExclusions.kind[1] | string | `"APIService"` |  |
| scraper.defaultExclusions.kind[2] | string | `"PodMetrics"` |  |
| scraper.defaultExclusions.kind[3] | string | `"NodeMetrics"` |  |
| scraper.defaultExclusions.kind[4] | string | `"endpoints.discovery.k8s.io"` |  |
| scraper.defaultExclusions.kind[5] | string | `"endpointslices.discovery.k8s.io"` |  |
| scraper.defaultExclusions.kind[6] | string | `"leases.coordination.k8s.io"` |  |
| scraper.defaultExclusions.kind[7] | string | `"podmetrics.metrics.k8s.io"` |  |
| scraper.defaultExclusions.kind[8] | string | `"nodemetrics.metrics.k8s.io"` |  |
| scraper.defaultExclusions.kind[9] | string | `"customresourcedefinition"` |  |
| scraper.defaultExclusions.labels."canaries.flanksource.com/check" | string | `"*"` |  |
| scraper.defaultExclusions.labels."canaries.flanksource.com/check-id" | string | `"*"` |  |
| scraper.defaultExclusions.labels."canaries.flanksource.com/generated" | string | `"true"` |  |
| scraper.defaultExclusions.labels."canary-checker.flanksource.com/check" | string | `"*"` |  |
| scraper.defaultExclusions.labels."canary-checker.flanksource.com/generated" | string | `"*"` |  |
| scraper.defaultExclusions.name | list | `[]` |  |
| scraper.defaultExclusions.namespace | list | `[]` |  |
| scraper.defaultRelationships[0].kind.expr | string | `"has(spec.claimRef) ? spec.claimRef.kind : ''"` |  |
| scraper.defaultRelationships[0].name.expr | string | `"has(spec.claimRef) ? spec.claimRef.name : ''"` |  |
| scraper.defaultRelationships[0].namespace.expr | string | `"has(spec.claimRef) ? spec.claimRef.namespace : ''"` |  |
| scraper.defaultRelationships[1].kind.value | string | `"GitRepository"` |  |
| scraper.defaultRelationships[1].name.expr | string | `"has(spec.sourceRef) ? spec.sourceRef.name : '' "` |  |
| scraper.defaultRelationships[1].namespace.expr | string | `"has(spec.sourceRef) && has(spec.sourceRef.namespace)  ? spec.sourceRef.namespace : metadata.namespace"` |  |
| scraper.defaultTransform.changes.exclude[0] | string | `"details.source.component == \"canary-checker\" && (change_type == \"Failed\" || change_type == \"Pass\")"` |  |
| scraper.defaultTransform.changes.exclude[1] | string | `"change_type == \"diff\" && config_type == \"MissionControl::Canary\" && summary.startsWith(\"status.\")"` |  |
| scraper.defaultTransform.changes.exclude[2] | string | `"config_type == \"Kubernetes::Node\" && summary == \"status.images\""` |  |
| scraper.defaultTransform.changes.exclude[3] | string | `"has(details.source) && details.source.component == \"kustomize-controller\" && details.reason == \"ReconciliationSucceeded\""` |  |
| scraper.defaultTransform.changes.exclude[4] | string | `"config_type.startsWith(\"Kubernetes::\") && summary == \"metadata.annotations.endpoints.kubernetes.io/last-change-trigger-time\""` |  |
| scraper.defaultTransform.changes.exclude[5] | string | `"change_type == \"diff\" && summary == \"status.reconciledAt\" && config != null && has(config.apiVersion) && config.apiVersion == \"argoproj.io/v1alpha1\" && has(config.kind) && config.kind == \"Application\"\n"` |  |
| scraper.defaultTransform.changes.exclude[6] | string | `"config_type == 'Kubernetes::Pod' && jq('.metadata?.ownerReferences?[0]?.apiVersion', config) == 'batch/v1' && (\n  severity == 'info' ||\n  (change_type == 'diff' && summary.contains('metadata'))\n)\n"` |  |
| scraper.defaultTransform.changes.mapping[0].filter | string | `"change.change_type == 'diff' && jq('.status.containerStatuses[0].lastState.terminated.reason', patch) == 'OOMKilled'"` |  |
| scraper.defaultTransform.changes.mapping[0].severity | string | `"high"` |  |
| scraper.defaultTransform.changes.mapping[0].type | string | `"OOMKilled"` |  |
| scraper.defaultTransform.changes.mapping[1].filter | string | `"change.change_type == 'diff' && jq('[.status.initContainerStatuses[]?.restartCount,.status.containerStatuses[]?.restartCount, 0]', patch).all(rc, rc != 0)\n"` |  |
| scraper.defaultTransform.changes.mapping[1].severity | string | `"high"` |  |
| scraper.defaultTransform.changes.mapping[1].type | string | `"PodCrashed"` |  |
| scraper.defaultTransform.changes.mapping[2].filter | string | `"change.change_type == 'diff' && jq('.status.containerStatuses[]?.lastState?.terminated?.exitCode', patch) == 0"` |  |
| scraper.defaultTransform.changes.mapping[2].type | string | `"Completed"` |  |
| scraper.defaultTransform.changes.mapping[3].filter | string | `"change.change_type == 'diff' && jq('.status.containerStatuses[]?.lastState?.terminated?.exitCode', patch) == 143"` |  |
| scraper.defaultTransform.changes.mapping[3].type | string | `"Terminated"` |  |
| scraper.defaultTransform.changes.mapping[4].filter | string | `"change.change_type == 'diff' && jq('.status.conditions[]? | select(.type == \"Healthy\").message', patch).contains('Health check passed')\n"` |  |
| scraper.defaultTransform.changes.mapping[4].type | string | `"HealthCheckPassed"` |  |
| scraper.defaultTransform.changes.mapping[5].filter | string | `"change.change_type == 'diff' && jq('.status.conditions[]? | select(.type == \"Healthy\").message', patch).contains('Health check failed')\n"` |  |
| scraper.defaultTransform.changes.mapping[5].type | string | `"HealthCheckFailed"` |  |
| scraper.defaultTransform.exclude | list | `[]` |  |
| scraper.defaultTransform.mask[0].jsonpath | string | `"$..['password','bearer','clientSecret','personalAccessToken','certificate','secretKey','token'].value"` |  |
| scraper.defaultTransform.mask[0].selector | string | `"config_class == 'Connection'"` |  |
| scraper.defaultTransform.mask[0].value | string | `"******"` |  |
| scraper.defaultTransform.relationship[0].external_id.expr | string | `"config.status.atProvider.id.lowerAscii()"` |  |
| scraper.defaultTransform.relationship[0].filter | string | `"config_type.startsWith(\"Crossplane::\") && has(config.status) && has(config.status.atProvider) && has(config.status.atProvider.id)"` |  |
| scraper.defaultTransform.relationship[1].filter | string | `"config_type == \"Kubernetes::Service\""` |  |
| scraper.defaultTransform.relationship[1].name.expr | string | `"has(config.spec.selector) && has(config.spec.selector.name) ? config.spec.selector.name : ''\n"` |  |
| scraper.defaultTransform.relationship[1].type.value | string | `"Kubernetes::Deployment"` |  |
| scraper.defaultTransform.relationship[2].expr | string | `"config.spec.volumes.\n  filter(item, has(item.persistentVolumeClaim)).\n  map(item, {\"type\": \"Kubernetes::PersistentVolumeClaim\", \"name\": item.persistentVolumeClaim.claimName}).\n  toJSON()\n"` |  |
| scraper.defaultTransform.relationship[2].filter | string | `"config_type == 'Kubernetes::Pod' && has(config.spec) && has(config.spec.volumes)"` |  |
| scraper.defaultWatch[0].apiVersion | string | `"v1"` |  |
| scraper.defaultWatch[0].kind | string | `"Namespace"` |  |
| scraper.defaultWatch[1].apiVersion | string | `"v1"` |  |
| scraper.defaultWatch[1].kind | string | `"Node"` |  |
| scraper.defaultWatch[2].apiVersion | string | `"v1"` |  |
| scraper.defaultWatch[2].kind | string | `"Pod"` |  |
| scraper.defaultWatch[3].apiVersion | string | `"apps/v1"` |  |
| scraper.defaultWatch[3].kind | string | `"Deployment"` |  |
| scraper.defaultWatch[4].apiVersion | string | `"apps/v1"` |  |
| scraper.defaultWatch[4].kind | string | `"ReplicaSet"` |  |
| scraper.defaultWatch[5].apiVersion | string | `"apps/v1"` |  |
| scraper.defaultWatch[5].kind | string | `"StatefulSet"` |  |
| scraper.defaultWatch[6].apiVersion | string | `"apps/v1"` |  |
| scraper.defaultWatch[6].kind | string | `"DaemonSet"` |  |
| scraper.defaultWatch[7].apiVersion | string | `"batch/v1"` |  |
| scraper.defaultWatch[7].kind | string | `"CronJob"` |  |
| scraper.defaultWatch[8].apiVersion | string | `"batch/v1"` |  |
| scraper.defaultWatch[8].kind | string | `"Job"` |  |
| scraper.event.exclusions.reason[0] | string | `"SuccessfulCreate"` |  |
| scraper.event.exclusions.reason[1] | string | `"Created"` |  |
| scraper.event.exclusions.reason[2] | string | `"DNSConfigForming"` |  |
| scraper.event.exclusions.reason[3] | string | `"ArtifactUpToDate"` |  |
| scraper.event.exclusions.reason[4] | string | `"GarbageCollectionSucceeded"` |  |
| scraper.event.severityKeywords.error[0] | string | `"failed"` |  |
| scraper.event.severityKeywords.error[1] | string | `"error"` |  |
| scraper.event.severityKeywords.warn[0] | string | `"backoff"` |  |
| scraper.event.severityKeywords.warn[1] | string | `"nodeoutofmemory"` |  |
| scraper.exclusions.kind | list | `[]` |  |
| scraper.exclusions.labels | object | `{}` |  |
| scraper.exclusions.name | list | `[]` |  |
| scraper.exclusions.namespace | list | `[]` |  |
| scraper.name | string | `"kubernetes-{{ .Values.clusterName }}"` |  |
| scraper.relationships | list | `[]` |  |
| scraper.retention.changes | list | `[]` |  |
| scraper.retention.defaultChanges[0].age | string | `"1d"` |  |
| scraper.retention.defaultChanges[0].name | string | `"ReconciliationSucceeded"` |  |
| scraper.retention.defaultChanges[1].age | string | `"1d"` |  |
| scraper.retention.defaultChanges[1].name | string | `"ArtifactUpToDate"` |  |
| scraper.retention.defaultChanges[2].age | string | `"1d"` |  |
| scraper.retention.defaultChanges[2].name | string | `"GarbageCollectionSucceeded"` |  |
| scraper.retention.defaultChanges[3].age | string | `"1d"` |  |
| scraper.retention.defaultChanges[3].name | string | `"Pulling"` |  |
| scraper.retention.defaultChanges[4].age | string | `"1d"` |  |
| scraper.retention.defaultChanges[4].name | string | `"Pulled"` |  |
| scraper.retention.defaultChanges[5].age | string | `"7d"` |  |
| scraper.retention.defaultChanges[5].name | string | `"Killing"` |  |
| scraper.retention.defaultChanges[6].age | string | `"7d"` |  |
| scraper.retention.defaultChanges[6].name | string | `"Scheduled"` |  |
| scraper.retention.defaultChanges[7].age | string | `"7d"` |  |
| scraper.retention.defaultChanges[7].name | string | `"Started"` |  |
| scraper.retention.defaultChanges[8].age | string | `"4h"` |  |
| scraper.retention.defaultChanges[8].name | string | `"HealthCheckPassed"` |  |
| scraper.retention.staleItemAge | string | `"4h"` |  |
| scraper.schedule | string | `"@every 15m"` |  |
| scraper.transform.changes.exclude | list | `[]` |  |
| scraper.transform.changes.mapping | list | `[]` |  |
| scraper.transform.exclude | list | `[]` |  |
| scraper.transform.expr | string | `""` |  |
| scraper.transform.mask | list | `[]` |  |
| scraper.transform.relationship | list | `[]` |  |
| scraper.watch | list | `[]` |  |
| topology.enabled | bool | `true` |  |
| topology.groupBy.selector | object | `{}` |  |
| topology.groupBy.tag | string | `""` |  |
| topology.icon | string | `"kubernetes"` |  |
| topology.ingress.enableChecks | bool | `false` |  |
| topology.ingress.enabled | bool | `true` |  |
| topology.ingress.nameExpr | string | `"r.config.spec.rules.size() > 0 ? r.config.spec.rules[0].host : r.name"` |  |
| topology.name | string | `"{{ .Values.clusterName }}"` |  |
| topology.schedule | string | `"@every 5m"` |  |
| views.cluster.enabled | bool | `true` |  |
| views.cluster.sidebar | bool | `true` |  |
| views.enabled | bool | `true` |  |
| views.helm_releases.enabled | bool | `true` |  |
| views.helm_releases.sidebar | bool | `true` |  |
| views.pods.enabled | bool | `true` | if true, the view will be enabled A prometheus connection is required. |
| views.pods.sidebar | bool | `true` |  |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
