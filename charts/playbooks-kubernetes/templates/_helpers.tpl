
{{- define "exec-action-connections" -}}
connections:
  fromConfigItem: '$(.config.id)'
  {{- if .Values.connections.podIdentity }}
  eksPodIdentity: true
  {{- end }}
  {{- if .Values.connections.serviceAccount }}
  serviceAccount: true
  {{- end }}
{{- end }}
