{{- define "git-origin" -}}
{{- omit .Values.git "url" "base" "branch" | toYaml}}
url: $(.git.git.url | strings.ReplaceAll "ssh://git@" "https://")
base: "$(.git.git.branch)"
{{- end}}


{{- define "playbook-annotations" -}}
"mission-control/playbook": $(.playbook.name)
"mission-control/run": $(.run.id)
"mission-control/createdBy": $(.user.name)
{{- end}}


{{- define "git-pr" -}}
{{- if (index . 0).Values.createPullRequest }}
pr:
  title: {{ index . 1}}
{{- end}}
{{- end}}
