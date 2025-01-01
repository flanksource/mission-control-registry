# mission-control-playbooks-ai

Flanksource Mission Control Playbooks that uses AI action

## Values

| Key                             | Type   | Default | Description                                                                                |
| ------------------------------- | ------ | ------- | ------------------------------------------------------------------------------------------ |
| diagnose.cluster                | string | `""`    | name of the cluster                                                                        |
| diagnose.enabled                | bool   | `true`  | create a playbook that can diagnose an unhealthy kubernetes resource in the given cluster. |
| diagnose.systemPrompt           | string | `""`    | Optional system prompt for the LLM. If not provided, a default prompt will be used.        |
| diganoseToSlack.cluster         | string | `""`    | name of the cluster                                                                        |
| diganoseToSlack.enabled         | bool   | `true`  | and send the diagnosis to slack.                                                           |
| diganoseToSlack.slackConnection | string | `""`    | connection string for slack                                                                |
| diganoseToSlack.systemPrompt    | string | `""`    | Optional system prompt for the LLM. If not provided, a default prompt will be used.        |
| global.connection               | string | `""`    | LLM connection: one of ollama, openai or anthropic                                         |

## Maintainers

| Name        | Email | Url |
| ----------- | ----- | --- |
| Flanksource |       |     |
