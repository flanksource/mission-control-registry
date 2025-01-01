# mission-control-playbooks-ai

Flanksource Mission Control Playbooks that uses AI action

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| diagnose.enabled | bool | `true` | create a playbook that diagnoses cataloges |
| diagnose.notification.enabled | bool | `true` | create a playbook that diagnoses cataloges and send the diagnosis report to slack. |
| diagnose.notification.systemPrompt | string | `""` | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.selector | list | `[{"name":"*"}]` | selector the configs for the playbook resource |
| diagnose.systemPrompt | string | `""` | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| global.llm_connection | string | `""` | LLM connection: one of ollama, openai or anthropic |
| slack.connection | string | `""` | connection string for slack |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
