{{/*
Expand the name of the chart.
*/}}
{{- define "mssql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mssql.fullname" -}}
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
{{- define "mssql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mssql.labels" -}}
helm.sh/chart: {{ include "mssql.chart" . }}
{{ include "mssql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mssql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mssql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Connection string - returns url if set, otherwise builds connection:// reference
*/}}
{{- define "mssql.connection" -}}
{{- if .Values.url -}}
connection: {{ .Values.url }}
{{- else -}}
connection: connection://{{ .Release.Namespace }}/{{ .Values.connectionName }}
{{- end -}}
{{- end }}

{{- define "mssql.connection-playbook" -}}
{{- if .Values.url -}}
url: {{ .Values.url }}
{{- else -}}
connection: connection://{{ .Release.Namespace }}/{{ .Values.connectionName }}
{{- end -}}
{{- end }}


{{/*
Playbook approvers - renders approval block if approvers are configured
*/}}
{{- define "mssql.approvers" -}}
{{- if or .Values.approvers.people .Values.approvers.teams }}
approval:
  type: any
  approvers:
    {{- with .Values.approvers.people }}
    people:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.approvers.teams }}
    teams:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end -}}
{{- end }}
