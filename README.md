# Mission Control Registry

A collection of Helm charts for Flanksource Mission Control integrations, playbooks, and views.

## Available Charts

| Chart                  | Description                        | Dependencies                         |
| ---------------------- | ---------------------------------- | ------------------------------------ |
| `aws`                  | AWS resource scraping and topology | AWS credentials                      |
| `azure`                | Azure resource scraping            | Azure credentials                    |
| `gcp`                  | Google Cloud resource scraping     | GCP credentials                      |
| `kubernetes`           | Kubernetes cluster monitoring      | Kubernetes cluster                   |
| `kubernetes-view`      | Kubernetes visualization views     | Mission Control, optional Prometheus |
| `mission-control`      | Core Mission Control deployment    | PostgreSQL, Redis                    |
| `playbooks-kubernetes` | Kubernetes automation playbooks    | Kubernetes cluster                   |
| `playbooks-flux`       | Flux GitOps playbooks              | Flux deployment                      |
| `mongo-atlas`          | MongoDB Atlas monitoring           | MongoDB Atlas API key                |
| `prometheus`           | Prometheus topology integration    | Prometheus server                    |
| `flux`                 | Flux GitOps topology               | Flux deployment                      |
| `argocd`               | ArgoCD topology integration        | ArgoCD deployment                    |

## Adding a New Chart

### Step 1: Create Chart Structure

Create the basic chart directory structure.
Example: To create a new chart `my-chart`

```bash
mkdir -p charts/my-chart/templates
```

### Step 2: Create Chart.yaml

```yaml
# charts/my-chart/Chart.yaml
apiVersion: v2
name: mission-control-my-chart
description: A Helm chart for My Service integration with Mission Control
icon: https://github.com/flanksource/docs/blob/main/docs/images/flanksource-icon.png?raw=true
type: application
version: 0.1.0
appVersion: '1.0.0'
maintainers:
  - name: Flanksource
```

### Step 3:

- [ ] Create Template Helpers
- [ ] Create Resource Templates
- [ ] Add Installation Notes

### Step 4: Copy boilerplate files

```bash
cd charts/my-chart/templates

cp ../kubernetes-view/Makefile .
cp ../kubernetes-view/.helmignore .
```

### Step 5: Define Values Structure

Create `values.yaml` with proper schema annotations.

Generate the values schema from the `values.yaml` file.

```bash
# This will create a `values.schema.json` file based on the `@schema` annotations in your `values.yaml`.
make values.schema.json
```

### Step 6: Generate README.md

Generate the README.md from the chart metadata.

```bash
make README.md
```

### Step 7: Lint

Create CI test values for linting.

```bash
mkdir -p charts/my-chart/ci
```

This file should contain the minimum values to test the chart.

```bash
make lint
```

### Step 8: Test your chart with

```bash
# Validate template rendering
helm template my-release ./charts/my-chart \
 --set clusterName="test-cluster"

# Install for testing
helm install my-release ./charts/my-chart \
 --set clusterName="test-cluster"
```
