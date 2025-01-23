# mission-control-playbooks-ai

Flanksource Mission Control Playbooks that uses AI action

## Values

| Key                                        | Type   | Default                                                                           | Description                                                                         |
| ------------------------------------------ | ------ | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| diagnose.enabled                           | bool   | `true`                                                                            | create a playbook that diagnoses cataloges                                          |
| diagnose.notification.enabled              | bool   | `true`                                                                            | create a playbook that diagnoses cataloges and send the diagnosis report to slack.  |
| diagnose.notification.systemPrompt         | string | `trimmed`                                                                         | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.playbooksRecommender.enabled      | bool   | `true`                                                                            | create a playbook that diagnoses cataloges and send the diagnosis report to slack.  |
| diagnose.playbooksRecommender.selector     | list   | `[{"name":"*"}]`                                                                  | selector the playbooks to recommend                                                 |
| diagnose.playbooksRecommender.systemPrompt | string | `trimmed`                                                                         | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.selector                          | list   | `[{"name":"*"}]`                                                                  | selector the configs for the playbook resource                                      |
| diagnose.systemPrompt                      | string | `trimmed`                                                                         | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.timeframe.analysis                | string | `"7d"`                                                                            | Duration to look back at config's analyses.                                         |
| diagnose.timeframe.changes                 | string | `"24h"`                                                                           | Duration to look back at configs changes.                                           |
| diagnose.timeframe.relatedAnalysis         | string | `"7d"`                                                                            | Duration to look back at the analyses of related configs.                           |
| diagnose.timeframe.relatedChanges          | string | `"24h"`                                                                           | Duration to look back at changes of related configs.                                |
| global.llm_connection                      | string | `""`                                                                              | LLM connection: one of ollama, openai or anthropic                                  |
| slack.connection                           | string | `""`                                                                              | connection string for slack                                                         |

## Maintainers

| Name        | Email | Url |
| ----------- | ----- | --- |
| Flanksource |       |     |
