# Verification harness

Two checks that `ct lint` cannot make, because the interesting parts of a View are its
queries — and those only mean anything against a real database.

Neither runs in chart CI: `verify_queries.py` needs a populated Mission Control database,
and `validate_schema.py` needs a checkout of the View CRD. Run them by hand after changing
a template.

## verify_queries.py

Renders the chart, runs every `queries.*.sql` block against `$DB_URL`, loads the results
into an in-memory SQLite database the way `views/run.go` does, then replays every panel
and `merge` query against it.

This is the only way to catch the dialect split before deploying: the `queries` run on
Postgres, but `panels[].query` and `merge` run on SQLite, so `date_trunc` in a panel is a
runtime error no amount of linting will find.

```sh
export DB_URL=postgres://…      # a Mission Control database with cost data
python3 hack/verify_queries.py
```

Reports a row count per query and per panel. A panel returning zero rows is flagged
`<< EMPTY` — usually a column name that does not survive the SQLite round trip.

View variables are substituted with the defaults at the top of the script; edit `VARS` to
exercise a different currency, window, or ownership key.

## validate_schema.py

Renders the chart and validates each View against the CRD's OpenAPI schema — catching
invalid column types, panel types, and enum values that `helm lint` passes over.

```sh
# defaults to ~/Work/incident-commander/config/crds/…
VIEW_CRD=/path/to/mission-control.flanksource.com_views.yaml python3 hack/validate_schema.py
```

## Requirements

`helm`, `psql`, and Python with `pyyaml` and `jsonschema`.
