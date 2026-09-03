# mission-control-cost-view

A Helm chart for cloud cost views in Flanksource Mission Control

## Views

| View | Answers |
| ---- | ------- |
| `cost-overview` | What did we spend, is it going up, and on what? Sidebar landing page. |
| `cost-by-owner` | Which team or namespace does the spend belong to? |
| `cost-by-account` | Which account is it billed to, and how much of it reaches a resource? |
| `cost-movers` | What changed since last period, ranked by dollars rather than percent? |
| `cost-config-tab` | What does this one resource cost? Appears as a tab on cloud config pages. |

## Reading the numbers

**Costs are never summed across currencies.** Every view filters to the one picked in
the Currency selector. Mixing currencies produces a number that means nothing, so the
views decline to do it rather than guessing a conversion.

**`effective_cost` is the headline metric** — spend after discounts, commitments and
credits. `list_cost` is on-demand pricing, and the gap between them is reported as
savings. `billed_cost` (what lands on the invoice) is deliberately not shown: it moves
with billing-period boundaries rather than with usage, which makes it the wrong number
for a trend line.

**The newest bucket is always partial.** Cloud billing exports land hours to days after
the usage, and on top of that the compaction job runs every 30m and the summary matview
refreshes every 15m. Every view carries a Data freshness panel reporting how far behind
the data actually is. A final bar that looks like a saving is nearly always just an
export that has not arrived.

**Resolution degrades with age.** Charges are stored hourly for the first 48h, daily to
90 days, then monthly to the 365-day retention limit. A 90-day chart cannot show hourly
detail because those rows no longer exist; the freshness panel reports the finest grain
present in the selected window.

**Ownership comes off the config item, not the charge.** Cost rows carry no resource
tags — the only label on a charge is the key it was resolved by. So `cost-by-owner`
reads the selected key from each config item's labels, then its tags. Resources with
neither, and spend that never reached a resource, group under `(unallocated)`.

## Attribution

Spend that cannot be resolved to a resource of its own is booked against the account's
root config item, and `cost-by-account` splits it into two very different cases:

- **Unallocatable** — tax, support, credits, shared fees. There is no resource to
  attribute it to, and there never will be. The scrapers mark these with a
  `<provider>:unallocated:` resource id.
- **Unresolved resource** — the charge names a real resource that the catalog has not
  discovered. This is a scrape coverage gap, not a billing fact. The **Undiscovered
  resources** panel lists them by spend; each row is a resource worth scraping.

A healthy install has most spend Attributed and a small, stable Unallocatable slice. A
large Unresolved slice means the cost scraper is ahead of the resource scrapers.

## Known issue: duplicate cost bookings

Charges are re-resolved on every scrape, and the merge key on `config_cost_compact`
includes `config_id`. When a charge's resolution target changes — which happens every
time a resource is discovered *after* its costs first landed, and the charge moves from
the account root to the resource itself — the earlier booking is not retired. Both rows
survive, and summing the table counts that charge twice.

Every query in this chart therefore reads through a `deduped` CTE that keeps one row per
`(source_key, fingerprint, period_start, period_end)`, preferring the resource-level
booking so attribution stays as specific as the data allows.

Set `deduplicate: false` to read the table directly once the ingest pipeline retires
superseded bookings, at which point the CTE becomes dead weight and should be removed.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| connection | string | `"connection://mission-control-db"` |  |
| currencies[0] | string | `"USD"` |  |
| deduplicate | bool | `true` |  |
| enabled | bool | `true` |  |
| labels | object | `{}` |  |
| ownershipKeys[0] | string | `"team"` |  |
| ownershipKeys[1] | string | `"namespace"` |  |
| rootConfigTypes[0] | string | `"AWS::::Account"` |  |
| rootConfigTypes[1] | string | `"GCP::Project"` |  |
| rootConfigTypes[2] | string | `"GCP::Organization"` |  |
| views.account.enabled | bool | `true` |  |
| views.cacheMaxAge | string | `"30m"` |  |
| views.configTab.enabled | bool | `true` |  |
| views.configTab.types[0] | string | `"AWS::*"` |  |
| views.configTab.types[1] | string | `"GCP::*"` |  |
| views.configTab.types[2] | string | `"Azure::*"` |  |
| views.enabled | bool | `true` |  |
| views.movers.enabled | bool | `true` |  |
| views.movers.threshold | int | `1` |  |
| views.overview.enabled | bool | `true` |  |
| views.overview.limit | int | `100` |  |
| views.overview.sidebar | bool | `true` |  |
| views.owner.enabled | bool | `true` |  |
| windows[0] | string | `"7 days"` |  |
| windows[1] | string | `"30 days"` |  |
| windows[2] | string | `"90 days"` |  |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Flanksource |  |  |
