{{/*
Parse connection string into namespace and name components
Usage: {{ include "parse-connection" .Values.slack.connection }}
*/}}
{{- define "parse-connection" -}}
{{- $parts := regexSplit "connection://" . -1 }}
{{- if eq (len $parts) 2 }}
{{- $nameParts := regexSplit "/" (index $parts 1) -1 }}
{{- if eq (len $nameParts) 2 }}
name: {{ index $nameParts 1 }}
namespace: {{ index $nameParts 0 }}
{{- end }}
{{- end }}
{{- end }} 
{{/*
Render Scope targets for a list of connection strings, skipping the ones that
aren't of the form connection://<namespace>/<name>.
Usage: {{ include "connection-scope-targets" (list .Values.slack.connection .Values.global.llm_connection) }}
*/}}
{{- define "connection-scope-targets" -}}
{{- range (. | uniq) }}
{{- with include "parse-connection" . }}
{{- $connection := . | fromYaml }}
- connection:
    name: {{ $connection.name | quote }}
    namespace: {{ $connection.namespace | quote }}
{{- end }}
{{- end }}
{{- end }}
