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