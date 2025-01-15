{{- define "git-origin" -}}
{{- omit .Values.git "url" "base" "branch" | toYaml}}
url: $(.git.git.url | strings.ReplaceAll "ssh://git@" "https://")
base: "$(.git.git.branch)"
{{- end}}

{{/*
Expand the name of the chart.
*/}}
{{- define "helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm.labels" -}}
helm.sh/chart: {{ include "helm.chart" . }}
{{ include "helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.helm.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.helm.io/managed-by: {{ .Release.Service }}
{{- range $key, $val := .Values.labels }}
{{ $key }}: {{ $val | quote }}
{{- end}}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm.selectorLabels" -}}
app.helm.io/name: {{ include "helm.name" . }}
app.helm.io/instance: {{ .Release.Name }}
{{- end }}
