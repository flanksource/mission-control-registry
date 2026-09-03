"""Validate the rendered views against the View CRD's OpenAPI schema."""
import os, pathlib, subprocess, sys, yaml, json, jsonschema

CHART = str(pathlib.Path(__file__).resolve().parent.parent)
CRD = os.environ.get(
    "VIEW_CRD",
    str(pathlib.Path.home() / "Work/incident-commander/config/crds"
        / "mission-control.flanksource.com_views.yaml"),
)

crd = yaml.safe_load(open(CRD))
schema = crd["spec"]["versions"][0]["schema"]["openAPIV3Schema"]

def strip(node):
    """x-kubernetes-* keywords are not JSON Schema; drop them before validating."""
    if isinstance(node, dict):
        return {k: strip(v) for k, v in node.items() if not k.startswith("x-kubernetes")}
    if isinstance(node, list):
        return [strip(v) for v in node]
    return node

schema = strip(schema)
out = subprocess.run(["helm", "template", "cost", CHART, "--namespace", "mc"],
                     capture_output=True, text=True)
if out.returncode:
    sys.exit("helm template failed:\n" + out.stderr)

fails = 0
for doc in (d for d in yaml.safe_load_all(out.stdout) if d):
    name = doc["metadata"]["name"]
    errs = sorted(jsonschema.Draft4Validator(schema).iter_errors(doc), key=lambda e: e.path)
    if errs:
        fails += 1
        print(f"FAIL {name}")
        for e in errs[:6]:
            print(f"     {'/'.join(str(p) for p in e.absolute_path)}: {e.message[:160]}")
    else:
        print(f"ok   {name}")
sys.exit(1 if fails else 0)
