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

Bounded to twice the selected window, which is the widest any view needs — the
prior-period comparison. One charge is one row: config_cost_compact is unique on
(source_key, fingerprint, period_start, period_end), so summing it is summing the bill.

Callers write:  WITH {{ include "cost-view.costSeries" . | nindent 10 }}
*/}}
{{- define "cost-view.costSeries" -}}
costs AS (
  SELECT cc.* FROM config_cost_compact cc
  WHERE cc.period_start >= now() - INTERVAL '$(.var.window)' * 2
)
{{- end }}

{{/*
Ownership attribution. Cost rows carry no resource tags of their own — the label on a
cost row is only the key it was resolved by — so ownership comes off the config item.
Labels win over tags because cloud resource tags land in labels.

A resource carrying no such key groups under "(unset)", which says what is true of it —
the key was never set — rather than making a claim about whether the spend could have
reached a resource at all. That is a separate question, and cost-view.attributionBucket
is where it is answered.
*/}}
{{- define "cost-view.owner" -}}
COALESCE(NULLIF(ci.labels->>'$(.var.ownership)', ''), NULLIF(ci.tags->>'$(.var.ownership)', ''), '(unset)')
{{- end }}

{{/*
An amount, in the selected currency, written the way an invoice writes it.

Takes the name of a numeric column already in scope; it is read three times, so an
aggregate belongs in a CTE rather than here. The sign leads the symbol, so a credit reads
-$4.20 rather than $-4.20, and is taken from the rounded amount so a value too small to
show does not print as a negative zero.

Only the currencies with a symbol most readers know get one. Anything else is prefixed
with its ISO code, which is unambiguous where an unfamiliar symbol would not be.

Callers write:  {{ include "cost-view.humanSpend" "a.cost" }} AS spend,
*/}}
{{- define "cost-view.humanSpend" -}}
CASE WHEN round({{ . }}, 2) < 0 THEN '-' ELSE '' END
    || CASE '$(.var.currency)'
         WHEN 'USD' THEN '$'
         WHEN 'EUR' THEN '€'
         WHEN 'GBP' THEN '£'
         ELSE '$(.var.currency)' || ' '
       END
    || to_char(round(abs({{ . }}), 2), 'FM999,999,999,990.00')
{{- end }}

{{/*
The sub-account a charge was billed to — a GCP project, an AWS member account.

Providers bill some charges to the billing account itself and name no sub-account at
all: tax, support, subscriptions, invoice adjustments. Those keep the billing account
id, so the row says which account it came from and two billing accounts never collapse
into one row.

Callers write:  {{- include "cost-view.accountLabel" . | nindent <n> }} AS account,
*/}}
{{- define "cost-view.accountLabel" -}}
CASE
    WHEN NULLIF(d.focus->>'sub_account_id', '') IS NOT NULL
      THEN d.focus->>'sub_account_id'
    WHEN NULLIF(d.focus->>'billing_account_id', '') IS NOT NULL
      THEN (d.focus->>'billing_account_id') || ' (billing account)'
    ELSE '(no account)'
  END
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
Charges naming a resource the catalog does not hold, as predicates on a `costs d` joined
to `config_items ci`.

Being booked against the account root is evidence the catalog was missing the resource
when the charge was last resolved, not that it is missing now. A charge is only
re-resolved while its billing period is still being restated, so a resource discovered
after its first charges landed leaves those charges pointing at the root for good. Ask the
catalog directly instead, and list only what it genuinely does not have. Soft-deleted
items count as discovered: a retired resource is one the catalog knows about.

Callers write:  AND {{ include "cost-view.undiscovered" . | nindent <n> }}
*/}}
{{- define "cost-view.undiscovered" -}}
ci.type IN ({{ include "cost-view.rootTypes" . }})
AND d.external_id IS NOT NULL
AND d.external_id NOT LIKE '%:unallocated:%'
AND NOT EXISTS (
  SELECT 1 FROM config_items known
  WHERE known.external_id @> ARRAY[d.external_id]
)
{{- end }}

{{/*
Charges the provider books to an account rather than to anything inside it, as predicates
on a `costs d` joined to `config_items ci`. The scrapers mark these with a
`<provider>:unallocated:` resource id, so there is no resource to find and never will be.

Callers write:  AND {{ include "cost-view.unallocated" . | nindent <n> }}
*/}}
{{- define "cost-view.unallocated" -}}
ci.type IN ({{ include "cost-view.rootTypes" . }})
AND d.external_id LIKE '%:unallocated:%'
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
