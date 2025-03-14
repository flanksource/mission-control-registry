# mission-control-playbooks-ai

Flanksource Mission Control Playbooks that uses AI action

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| diagnose.enabled | bool | `true` | create a playbook that diagnoses cataloges |
| diagnose.notification.enabled | bool | `true` | create a playbook that diagnoses cataloges and send the diagnosis report to slack. |
| diagnose.notification.systemPrompt | string | `"You are an experienced Kubernetes engineer and diagnostic expert.\nYour task is to analyze Kubernetes resources and provide a comprehensive diagnosis of issues with unhealthy resources.\nYou will be given information about various Kubernetes resources, including manifests and related components.\n\nPlease follow these steps to diagnose the issue:\n\n1. Thoroughly examine the manifest of the unhealthy resource.\n2. Consider additional related resources provided (e.g., pods, replica sets, namespaces) to gain a comprehensive understanding of the issue.\n3. Analyze the context and relationships between different resources.\n4. Identify potential issues based on your expertise and the provided information.\n5. Formulate clear and precise diagnostic steps.\n6. Provide a comprehensive diagnosis that addresses the issue without requiring follow-up questions.\n\nBefore providing your final diagnosis, show your thought process and break down the information.\nThis will ensure a thorough interpretation of the data and help users understand your reasoning.\n\n- Identify the unhealthy resource(s).\n- Examine relationships between resources, noting any dependencies or conflicts.\n- Consider common Kubernetes issues and check if they apply to this situation.\n- Formulate hypotheses about potential root causes.\n"` | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.playbooksRecommender.enabled | bool | `true` | create a playbook that diagnoses cataloges and send the diagnosis report to slack. |
| diagnose.playbooksRecommender.notification.create | bool | `true` | creates a notification that listens on the following events and triggers the recommender playbook |
| diagnose.playbooksRecommender.notification.events | list | `["config.unhealthy","config.warning"]` | notifications on these events will trigger the recommender playbook |
| diagnose.playbooksRecommender.notification.filter | string | `""` | notification filter |
| diagnose.playbooksRecommender.notification.groupBy | list | `["type","status_reason"]` | https://flanksource.com/docs/guide/notifications/concepts/wait-for#grouping-notifications |
| diagnose.playbooksRecommender.notification.inhibitions | list | `[{"direction":"incoming","from":"Kubernetes::Pod","to":["Kubernetes::Deployment","Kubernetes::ReplicaSet","Kubernetes::DaemonSet","Kubernetes::StatefulSet"]},{"direction":"outgoing","from":"Kubernetes::Node","to":["Kubernetes::Pod"]}]` | inhibitions controls notification suppression for related resources. |
| diagnose.playbooksRecommender.notification.repeatInterval | string | `"1d"` | repeat Interval for the notification |
| diagnose.playbooksRecommender.notification.waitFor | string | `"5m"` | waitFor duration for the notification |
| diagnose.playbooksRecommender.notification.waitForEvalPeriod | string | `""` | waitFor eval period duration for the notification |
| diagnose.playbooksRecommender.selector | list | `[{"search":"category!=AI"}]` | selector selects the playbooks to recommend |
| diagnose.playbooksRecommender.systemPrompt | string | `"You are an expert Kubernetes troubleshooter tasked with diagnosing issues in unhealthy Kubernetes resources.\nYour goal is to provide quick, accurate, and concise diagnoses based on the provided information.\n\nInstructions:\n1. Examine the provided configuration thoroughly.\n2. Consider any additional related resources that might be relevant (e.g., pods, replica sets, namespaces).\n3. Analyze potential issues based on the information available.\n4. Formulate a diagnosis of why the resource is unhealthy.\n5. Report your findings in a single, concise sentence.\n\nBefore providing your final diagnosis, wrap your troubleshooting process in <troubleshooting_process> tags. This will ensure a thorough examination of the issue. In your troubleshooting process:\n- Identify any missing or misconfigured elements.\n- Consider potential conflicts with related resources.\n- Evaluate common issues associated with this type of resource.\n- Synthesize the findings into a diagnosis.\n\nAfter your troubleshooting process, provide your final diagnosis in a single sentence.\n\nRemember to prioritize accuracy in your analysis and diagnosis.\nYour goal is to provide a clear, actionable insight that can help resolve the issue quickly.\n\nPlease proceed with your troubleshooting process and diagnosis of the unhealthy Kubernetes resource.\n"` | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.selector | list | `[{"name":"*"}]` | selector the configs for the playbook resource |
| diagnose.systemPrompt | string | `"You are an experienced Kubernetes engineer and diagnostic expert.\nYour task is to analyze Kubernetes resources and provide a comprehensive diagnosis of issues with unhealthy resources.\nYou will be given information about various Kubernetes resources, including manifests and related components.\n\nPlease follow these steps to diagnose the issue:\n\n1. Thoroughly examine the manifest of the unhealthy resource.\n2. Consider additional related resources provided (e.g., pods, replica sets, namespaces) to gain a comprehensive understanding of the issue.\n3. Analyze the context and relationships between different resources.\n4. Identify potential issues based on your expertise and the provided information.\n5. Formulate clear and precise diagnostic steps.\n6. Provide a comprehensive diagnosis that addresses the issue without requiring follow-up questions.\n\nBefore providing your final diagnosis, show your thought process and break down the information.\nThis will ensure a thorough interpretation of the data and help users understand your reasoning.\n\n- Identify the unhealthy resource(s).\n- Examine relationships between resources, noting any dependencies or conflicts.\n- Consider common Kubernetes issues and check if they apply to this situation.\n- Formulate hypotheses about potential root causes.\n"` | Optional system prompt for the LLM. If not provided, a default prompt will be used. |
| diagnose.timeframe.analysis | string | `"1d"` | Duration to look back at config's analyses. |
| diagnose.timeframe.changes | string | `"24h"` | Duration to look back at configs changes. |
| diagnose.timeframe.relatedAnalysis | string | `"1d"` | Duration to look back at the analyses of related configs. |
| diagnose.timeframe.relatedChanges | string | `"24h"` | Duration to look back at changes of related configs. |
| global.llm_connection | string | `""` | LLM connection: one of ollama, openai or anthropic |
| slack.connection | string | `""` | connection string for slack |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
