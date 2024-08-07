# Kubernetes

Schema generation:

Install the helm plugin

```bash
helm plugin install https://github.com/losisin/helm-values-schema-json.git
```

```bash
helm schema -indent 2 -schemaRoot.title='Schema for MongoDB Atlas bundle of Flanksource Mission Control' -input values.yaml
```
