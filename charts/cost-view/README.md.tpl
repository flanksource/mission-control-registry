{{ template "chart.header" . }}
{{ template "chart.deprecationWarning" . }}

{{ template "chart.description" . }}

{{ template "chart.homepageLine" . }}

## Views

| View | Answers |
| ---- | ------- |
| `cost-overview` | What did we spend, is it going up, and on what? Sidebar landing page. |
| `cost-by-owner` | Which team or namespace does the spend belong to? |
| `cost-by-account` | Which account is it billed to, and how much of it reaches a resource? |
| `cost-movers` | What changed since last period, ranked by dollars rather than percent? |
| `cost-unallocated` | What is on the bill that no resource could ever account for? |
| `cost-unresolved` | Which resources are costing money that the catalog has never seen? |

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
neither, and spend that never reached a resource, group under `(unset)` — a statement
about the key, not about whether the spend was attributable. Account rows in the
`cost-overview` table carry no owner at all, having no resource there was anything to own.

## Attribution

Spend that cannot be resolved to a resource of its own is booked against the account's
root config item, and `cost-by-account` splits it into two very different cases:

- **Unallocatable** — tax, support, credits, shared fees. There is no resource to
  attribute it to, and there never will be. The scrapers mark these with a
  `<provider>:unallocated:` resource id. The `cost-unallocated` view lists it by service
  and account, so it is subtracted knowingly rather than quietly missing.
- **Unresolved resource** — the charge names a real resource that the catalog has not
  discovered. This is a scrape coverage gap, not a billing fact. The `cost-unresolved`
  view lists them by spend; each row is a resource worth scraping.

A healthy install has most spend Attributed and a small, stable Unallocatable slice. A
large Unresolved slice means the cost scraper is ahead of the resource scrapers.

**Being booked at the root does not by itself mean undiscovered.** A charge is resolved
at scrape time and re-resolved only while its billing period is still being restated, so
a resource discovered after its first charges landed leaves those charges pointing at the
account root for good. `cost-unresolved` therefore asks the catalog directly and lists
only resource ids it genuinely does not hold; config-db's `ReattributeConfigCosts` job
moves the frozen charges onto their resource nightly.

{{ template "chart.sourcesSection" . }}

{{ template "chart.requirementsSection" . }}

{{ template "chart.valuesSection" . }}

{{ template "helm-docs.versionFooter" . }}

{{ template "chart.maintainersSection" . }}
