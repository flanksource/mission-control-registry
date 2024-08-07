{{/*
Expand the name of the chart.
*/}}
{{- define "mongo-atlas.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mongo-atlas.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mongo-atlas.labels" -}}
helm.sh/chart: {{ include "mongo-atlas.chart" . }}
{{ include "mongo-atlas.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.mongo-atlas.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.mongo-atlas.io/managed-by: {{ .Release.Service }}
{{- range $key, $val := .Values.labels }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mongo-atlas.selectorLabels" -}}
app.mongo-atlas.io/name: {{ include "mongo-atlas.name" . }}
app.mongo-atlas.io/instance: {{ .Release.Name }}
{{- end }}