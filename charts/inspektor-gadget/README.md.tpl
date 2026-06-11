## Overview

This Helm chart deploys the Flanksource Mission Control [Inspektor Gadget](https://www.inspektor-gadget.io/) plugin. It registers a `Plugin` resource that enriches Kubernetes resources (Pods, Deployments, StatefulSets, DaemonSets, ReplicaSets, Jobs and CronJobs).

Optionally, it can also install the upstream `inspektor-gadget` chart as a dependency. Set `inspektor-gadget.enabled` to `true` and provide any upstream values under the `inspektor-gadget.*` key.

## Quickstart

Install only the Mission Control plugin:

```bash
helm install inspektor-gadget flanksource/mission-control-inspektor-gadget \
  --namespace mission-control
```

Install the plugin and the upstream inspektor-gadget chart:

```bash
helm install inspektor-gadget flanksource/mission-control-inspektor-gadget \
  --namespace mission-control \
  --set inspektor-gadget.enabled=true
```
