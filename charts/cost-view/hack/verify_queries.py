"""Render the cost-view chart, run every SQL query against Postgres, load the results
into SQLite the way the view engine does, then run every panel and merge query."""
import subprocess, sys, yaml, os, json, sqlite3, pathlib

CHART = str(pathlib.Path(__file__).resolve().parent.parent)
VARS = {"$(.var.currency)": "USD", "$(.var.window)": "90 days", "$(.var.ownership)": "team",
        "$(.var.config_id)": "38ac64a1-d64b-f0e4-ff8c-1c60fdd91616"}
DB = os.environ["DB_URL"]

def subst(s):
    for k, v in VARS.items():
        s = s.replace(k, v)
    return s

out = subprocess.run(["helm", "template", "cost", CHART, "--namespace", "mc"],
                     capture_output=True, text=True)
if out.returncode:
    sys.exit("helm template failed:\n" + out.stderr)

docs = [d for d in yaml.safe_load_all(out.stdout) if d]
print(f"rendered {len(docs)} view(s)\n")
fails = 0

for doc in docs:
    name = doc["metadata"]["name"]
    spec = doc["spec"]
    print(f"--- {name}")
    mem = sqlite3.connect(":memory:")

    for qname, q in (spec.get("queries") or {}).items():
        sql = q.get("sql", {}).get("query")
        if not sql:
            print(f"  skip {qname} (not a sql query)"); continue
        wrapped = f"SELECT coalesce(json_agg(t), '[]'::json) FROM ({subst(sql).rstrip().rstrip(';')}) t"
        r = subprocess.run(["psql", DB, "-tAX", "-v", "ON_ERROR_STOP=1", "-c", wrapped],
                           capture_output=True, text=True)
        if r.returncode:
            fails += 1
            print(f"  FAIL query {qname}")
            for l in [l for l in r.stderr.strip().splitlines() if l.strip()][:4]:
                print("       " + l)
            continue
        rows = json.loads(r.stdout)
        cols = list(q.get("columns") or (rows[0].keys() if rows else []))
        if not cols:
            print(f"  warn  {qname}: no rows and no column types declared"); continue
        mem.execute(f"CREATE TABLE {qname} ({','.join(chr(34)+c+chr(34) for c in cols)})")
        mem.executemany(
            f"INSERT INTO {qname} VALUES ({','.join('?' * len(cols))})",
            [[r_.get(c) for c in cols] for r_ in rows])
        print(f"  ok    query {qname:<14} {len(rows):>5} rows")

    for panel in spec.get("panels") or []:
        try:
            got = mem.execute(panel["query"]).fetchall()
            print(f"  ok    panel {panel['name']:<28} {len(got):>4} rows"
                  + ("   << EMPTY" if not got else ""))
        except Exception as e:
            fails += 1
            print(f"  FAIL panel {panel['name']}: {e}")

    if spec.get("merge"):
        try:
            got = mem.execute(spec["merge"]).fetchall()
            print(f"  ok    merge {len(got)} rows")
        except Exception as e:
            fails += 1
            print(f"  FAIL merge: {e}")
    print()

sys.exit(1 if fails else 0)
