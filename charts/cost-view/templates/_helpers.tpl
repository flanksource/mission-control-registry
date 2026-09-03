{{/*
Expand the name of the chart.
*/}}
{{- define "cost-view.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cost-view.fullname" -}}
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
{{- define "cost-view.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cost-view.labels" -}}
helm.sh/chart: {{ include "cost-view.chart" . }}
{{ include "cost-view.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cost-view.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cost-view.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Config types that unattributable spend is booked against, as a SQL IN list.
*/}}
{{- define "cost-view.rootTypes" -}}
{{- range $i, $t := .Values.rootConfigTypes }}{{ if $i }}, {{ end }}'{{ $t }}'{{ end }}
{{- end }}

{{/*
The cost series every query reads, as a named CTE.

A charge is re-resolved on every scrape, and the merge key includes config_id, so a
charge that was booked against the root config item before its own resource was
discovered keeps that booking forever alongside the newer one. Summing the table
directly therefore counts those charges twice. DISTINCT ON keeps one row per charge,
preferring the resource-level booking over the root so attribution stays as specific
as the data allows.

Bounded to twice the selected window, which is the widest any view needs — the
prior-period comparison. Duplicates of a charge always share its period, so bounding
by period first never splits a group.

Callers write:  WITH {{ include "cost-view.deduped" . | nindent 10 }}
*/}}
{{- define "cost-view.deduped" -}}
deduped AS (
{{- if .Values.deduplicate }}
  SELECT DISTINCT ON (cc.source_key, cc.fingerprint, cc.period_start, cc.period_end) cc.*
  FROM config_cost_compact cc
  JOIN config_items ci ON ci.id = cc.config_id
  WHERE cc.period_start >= now() - INTERVAL '$(.var.window)' * 2
  ORDER BY cc.source_key, cc.fingerprint, cc.period_start, cc.period_end,
           (ci.type IN ({{ include "cost-view.rootTypes" . }})), cc.updated_at DESC
{{- else }}
  SELECT cc.* FROM config_cost_compact cc
  WHERE cc.period_start >= now() - INTERVAL '$(.var.window)' * 2
{{- end }}
)
{{- end }}

{{/*
Ownership attribution. Cost rows carry no resource tags of their own — the label on a
cost row is only the key it was resolved by — so ownership comes off the config item.
Labels win over tags because cloud resource tags land in labels.
*/}}
{{- define "cost-view.owner" -}}
COALESCE(NULLIF(ci.labels->>'$(.var.ownership)', ''), NULLIF(ci.tags->>'$(.var.ownership)', ''), '(unallocated)')
{{- end }}

{{/*
How well a charge could be attributed. Anything booked against a root config item
either had no resource of its own (the scrapers mark those with a `<provider>:unallocated:`
resource id) or names a resource the catalog has not discovered.
*/}}
{{- define "cost-view.attributionBucket" -}}
CASE
    WHEN ci.type IN ({{ include "cost-view.rootTypes" . }})
         AND d.external_id LIKE '%:unallocated:%' THEN 'Unallocatable'
    WHEN ci.type IN ({{ include "cost-view.rootTypes" . }}) THEN 'Unresolved resource'
    ELSE 'Attributed'
  END
{{- end }}

{{/*
Currency and window, which every cost view offers. Values are interpolated into SQL,
so each is constrained to a fixed list rather than free text.

The window defaults to the second entry — the middle of a short/medium/long list — and
falls back to the only entry when just one is configured.
*/}}
{{- define "cost-view.baseTemplating" -}}
templating:
  - key: currency
    label: Currency
    default: {{ first .Values.currencies | quote }}
    values:
      {{- range .Values.currencies }}
      - {{ . | quote }}
      {{- end }}
  - key: window
    label: Window
    default: {{ if gt (len .Values.windows) 1 }}{{ index .Values.windows 1 | quote }}{{ else }}{{ first .Values.windows | quote }}{{ end }}
    values:
      {{- range .Values.windows }}
      - {{ . | quote }}
      {{- end }}
{{- end }}

{{/*
The base variables plus the ownership key, for the views that group by owner.
*/}}
{{- define "cost-view.templating" -}}
{{ include "cost-view.baseTemplating" . }}
  - key: ownership
    label: Group by
    default: {{ first .Values.ownershipKeys | quote }}
    values:
      {{- range .Values.ownershipKeys }}
      - {{ . | quote }}
      {{- end }}
{{- end }}

{{/*
Cache settings shared by every cost view.
*/}}
{{- define "cost-view.cache" -}}
cache:
  maxAge: {{ .Values.views.cacheMaxAge | quote }}
{{- end }}

{{/*
Describes the finest compaction level present, from the labels in .Values.grainLabels.

A level with no label falls through to its own name rather than to a guess: reporting
"level4" is honest where reporting "monthly" would be a claim about the data that nothing
has checked. Labels are single-quoted for SQL, so an apostrophe in one is doubled.
*/}}
{{- define "cost-view.grainCase" -}}
CASE
  WHEN MIN(grain) IS NULL THEN 'n/a'
{{- range $level, $label := .Values.grainLabels }}
  WHEN MIN(grain) = '{{ $level | replace "'" "''" }}' THEN '{{ $label | replace "'" "''" }}'
{{- end }}
  ELSE MIN(grain)
END
{{- end }}

{{/*
Data freshness, as rows for a properties panel. Billing exports land hours to days
late, so the trailing edge of every cost chart is always partly empty. Stating the
frontier is what stops a half-filled final bucket from being read as a saving.
*/}}
{{- define "cost-view.freshnessQuery" -}}
SELECT
  'Data through' AS label,
  COALESCE(to_char(MAX(period_end) AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI') || ' UTC',
           'no cost data') AS value
FROM config_cost_compact WHERE billing_currency = '$(.var.currency)'
UNION ALL
SELECT 'Billing lag',
  COALESCE(CASE
    WHEN EXTRACT(epoch FROM now() - MAX(period_end)) < 86400
      THEN round(EXTRACT(epoch FROM now() - MAX(period_end)) / 3600)::text || ' hours'
    ELSE round(EXTRACT(epoch FROM now() - MAX(period_end)) / 86400)::text || ' days'
  END, 'n/a')
FROM config_cost_compact WHERE billing_currency = '$(.var.currency)'
UNION ALL
SELECT 'Resolution',
{{- include "cost-view.grainCase" . | nindent 2 }}
FROM config_cost_compact
WHERE billing_currency = '$(.var.currency)'
  AND period_start >= now() - INTERVAL '$(.var.window)'
UNION ALL
SELECT 'Currencies present',
  COALESCE(string_agg(DISTINCT billing_currency, ', '), 'n/a')
FROM config_cost_compact WHERE period_start >= now() - INTERVAL '$(.var.window)'
{{- end }}
