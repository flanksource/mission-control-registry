{{/*
Expand the name of the chart.
*/}}
{{- define "kubernetes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubernetes.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kubernetes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubernetes.labels" -}}
helm.sh/chart: {{ include "kubernetes.chart" . }}
{{ include "kubernetes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $val := .Values.labels }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubernetes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubernetes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kubernetes.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kubernetes.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Metrics
*/}}
{{- define "kubernetes.topology.metricProperties.prometheus.cluster" -}}
- name: cpu
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).cluster_cpu) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          [{'name': 'cpu', 'value': int(results[0].value), 'headline': true, 'unit': 'millicores'}].toJSON()
- name: memory
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).cluster_memory) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          [{'name': 'memory', 'value': int(results[0].value), 'headline': true, 'unit': 'bytes'}].toJSON()
{{- end }}



{{- define "kubernetes.topology.metricProperties.prometheus.node" -}}
- name: cpu
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).node_cpu) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.node,
            'properties': [{'name': 'cpu', 'value': math.Ceil(int(r.value))}]
          }).toJSON()
- name: memory
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).node_memory) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.node,
            'properties': [{'name': 'memory', 'value': int(r.value)}]
          }).toJSON()

- name: ephemeral-storage
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).node_storage) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.instance,
            'properties': [{'name': 'memory', 'value': int(r.value)}]
          }).toJSON()
{{- end }}

{{- define "kubernetes.topology.metricProperties.prometheus.pod" -}}
- name: cpu
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).pod_cpu) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.pod,
            'properties': [{'name': 'cpu', 'value': math.Ceil(int(r.value))}]
          }).toJSON()
- name: memory
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).pod_memory) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.pod,
            'properties': [{'name': 'memory', 'value': int(r.value)}]
            }).toJSON()
{{- end }}


{{- define "kubernetes.topology.metricProperties.prometheus.namespace" -}}
- name: cpu
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).namespace_cpu) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.namespace,
            'properties': [{'name': 'cpu', 'value': math.Ceil(int(r.value))}]
          }).toJSON()
- name: memory
  lookup:
    prometheus:
    - query: {{tpl ((get .Values.metrics.queries .Values.metrics.type).namespace_memory) .}}
      connection: connection://{{ .Values.prometheus.connection }}
      display:
        expr: |
          dyn(results).map(r, {
            'name': r.namespace,
            'properties': [{'name': 'memory', 'value': int(r.value)}]
          }).toJSON()
{{- end }}

{{- define "kubernetes.topology.metricProperties.k8sMetrics.cluster" -}}
- name: cluster-metrics
  lookup:
    kubernetes:
    - kind: PodMetrics
      {{- with .Values.kubeconfig }}
      kubeconfig: {{ toYaml . | nindent 8}}
      {{- end}}
      display:
        expr: |
          [
            {'name': 'cpu', 'headline': true, 'unit': 'millicores', 'value': math.Add(dyn(results).map(r, r.Object).map(r, math.Add(r.containers.map(c, k8s.cpuAsMillicores(c.usage.cpu)))))},
            {'name': 'memory', 'headline': true, 'unit': 'bytes', 'value': math.Add(dyn(results).map(r, r.Object).map(r, math.Add(r.containers.map(c, k8s.memoryAsBytes(c.usage.memory)))))},
          ].toJSON()
{{- end }}

{{- define "kubernetes.topology.metricProperties.k8sMetrics.node" -}}
- name: node-metrics
  lookup:
    kubernetes:
      - kind: NodeMetrics
        {{- with .Values.kubeconfig }}
        kubeconfig: {{ toYaml . | nindent 10}}
        {{- end}}
        display:
          expr: |
            dyn(results).map(r, r.Object).map(r, {
              'name': r.metadata.name,
              'properties': [
                {'name': 'cpu', 'value': k8s.cpuAsMillicores(r.usage.cpu)},
                {'name': 'memory', 'value': k8s.memoryAsBytes(r.usage.memory)},
              ]}).toJSON()
{{- end }}

{{- define "kubernetes.topology.metricProperties.k8sMetrics.pod" -}}
- name: pod-metrics
  lookup:
    kubernetes:
      - kind: PodMetrics
        {{- with .Values.kubeconfig }}
        kubeconfig: {{ toYaml . | nindent 10}}
        {{- end}}
        display:
          expr: |
            dyn(results).map(r, r.Object).map(r, {
              'name': r.metadata.name,
              'properties': [
                {'name': 'cpu', 'value': math.Add(r.containers.map(c, k8s.cpuAsMillicores(c.usage.cpu)))},
                {'name': 'memory', 'value': math.Add(r.containers.map(c, k8s.memoryAsBytes(c.usage.memory)))},
              ]}).toJSON()
{{- end }}

{{- define "kubernetes.topology.metricProperties.k8sMetrics.namespace" -}}
forEach:
  properties:
    - name: namespace-metrics
      lookup:
        kubernetes:
          - kind: PodMetrics
            {{- with .Values.kubeconfig }}
            kubeconfig: {{ toYaml . | nindent 14}}
            {{- end}}
            namespaceSelector:
              name: '$(.component.name)'
            test:
              # To avoid no resources found error for empty namespaces
              expr: 'true'
            display:
              expr: |
                [
                  {'name': 'cpu', 'unit': 'millicores', 'headline': true, 'value': math.Add(dyn(results).map(r, r.Object).map(r, math.Add(r.containers.map(c, k8s.cpuAsMillicores(c.usage.cpu)))))},
                  {'name': 'memory', 'unit': 'bytes', 'headline': true, 'value': math.Add(dyn(results).map(r, r.Object).map(r, math.Add(r.containers.map(c, k8s.memoryAsBytes(c.usage.memory)))))},
                ].toJSON()
{{- end }}

{{- define "kubernetes.topology.metricProperties.cluster" -}}
{{- if .Values.prometheus.url }}
{{- include "kubernetes.topology.metricProperties.prometheus.cluster" . }}
{{- else if .Values.metrics.enabled }}
{{- include "kubernetes.topology.metricProperties.k8sMetrics.cluster" . }}
{{- end }}
{{- end }}

{{- define "kubernetes.topology.metricProperties.node" -}}
{{- if .Values.prometheus.url }}
{{- include "kubernetes.topology.metricProperties.prometheus.node" . }}
{{- else if .Values.metrics.enabled }}
{{- include "kubernetes.topology.metricProperties.k8sMetrics.node" . }}
{{- end }}
{{- end }}

{{- define "kubernetes.topology.metricProperties.pod" -}}
{{- if .Values.prometheus.url }}
{{- include "kubernetes.topology.metricProperties.prometheus.pod" . }}
{{- else if .Values.metrics.enabled }}
{{- include "kubernetes.topology.metricProperties.k8sMetrics.pod" . }}
{{- end }}
{{- end }}

{{- define "kubernetes.topology.metricProperties.namespace" -}}
{{- if .Values.prometheus.url }}
{{- include "kubernetes.topology.metricProperties.prometheus.namespace" . | nindent 2 }}
{{- else if .Values.metrics.enabled }}
{{- include "kubernetes.topology.metricProperties.k8sMetrics.namespace" . }}
{{- end }}
{{- end }}
