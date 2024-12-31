# mission-control-playbooks-ai

Flanksource Mission Control Playbooks that uses AI action

## Values

| Key                   | Type   | Default | Description                                                                         |
| --------------------- | ------ | ------- | ----------------------------------------------------------------------------------- |
| connection            | string | `""`    | LLM connection: one of ollama, openai or anthropic                                  |
| diagnose.cluster      | string | `""`    | name of the cluster                                                                 |
| diagnose.enabled      | bool   | `true`  | enable kubernetes diagnosing playbook                                               |
| diagnose.systemPrompt | string | `""`    | Optional system prompt for the LLM. If not provided, a default prompt will be used. |

## Maintainers

| Name        | Email | Url |
| ----------- | ----- | --- |
| Flanksource |       |     |
