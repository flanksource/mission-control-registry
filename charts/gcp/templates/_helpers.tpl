{{/*
Expand the name of the chart.
*/}}
{{- define "gcp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "gcp.fullname" -}}
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
{{- define "gcp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gcp.labels" -}}
helm.sh/chart: {{ include "gcp.chart" . }}
{{ include "gcp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gcp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gcp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "gcp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Recursively merge two dictionaries, concatenating arrays instead of overwriting
*/}}
{{- define "helpers.deepMerge" -}}
{{- $dst := mustDeepCopy (index . 0) -}}
{{- $src := index . 1 -}}
{{- range $key, $srcValue := $src }}
  {{- if hasKey $dst $key }}
    {{- $dstValue := index $dst $key }}
    {{- if and (kindIs "slice" $srcValue) (kindIs "slice" $dstValue) }}
      {{- $_ := set $dst $key (concat $dstValue $srcValue) }}
    {{- else if and (kindIs "map" $srcValue) (kindIs "map" $dstValue) }}
      {{- $_ := set $dst $key (include "helpers.deepMerge" (list $dstValue $srcValue) | fromYaml) }}
    {{- else }}
      {{- $_ := set $dst $key $srcValue }}
    {{- end }}
  {{- else }}
    {{- $_ := set $dst $key $srcValue }}
  {{- end }}
{{- end }}
{{- $dst | toYaml }}
{{- end }}
