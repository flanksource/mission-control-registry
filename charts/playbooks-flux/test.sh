# Config db run more than once for all relationships to form
# Also refresh config_summary_7d materialized view
# system user's email in people table should be set for git
# Run incident-commander in serve mode for git connection to by synced
# All of these should be run in AWS Cluster pointed in kubeconfig

#!/bin/bash
set -x
function runPlaybook() {
  all_args=("$@")
  echo "Running playbook $1 ${all_args[@]:1}"
  helm template ./ --set git.connection="connection://mission-control/github" --set createPullRequest=false | yq ea " . | select(.metadata.name == \"$1\")" | yq '.spec.actions[0].gitops.repo.branch |= "main" ' | incident-commander playbook run -v=5  /dev/stdin ${all_args[@]:1}

  # TODO: Fix playbook cmd ret code
  #if [[ "$?" != "0" ]]; then
    #exit 1
  #fi
}

function runPlaybookNoEditMain() {
  all_args=("$@")
  echo "Running playbook $1 ${all_args[@]:1}"
  #helm template ./ --set git.connection="connection://mission-control/github" --set createPullRequest=false | yq ea " . | select(.metadata.name == \"$1\")" | yq "... comments=\"\" " | incident-commander playbook run -v=5  /dev/stdin ${all_args[@]:1}
  helm template ./ --set git.connection="connection://mission-control/github" --set createPullRequest=false | yq ea " . | select(.metadata.name == \"$1\")"  | incident-commander playbook run -v=5  /dev/stdin ${all_args[@]:1}

  # TODO: Fix playbook cmd ret code
  #if [[ "$?" != "0" ]]; then
    #exit 1
  #fi
}

REPO_ORIGINAL_COMMIT="4a416ec6dbf5e82f6833cad1c21626ead2ed3791"

fileroot=$(pwd)

name=flux-$(date "+%H%M%S")
kustomization=$(kubectl -n mission-control exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::Kustomization name=flux-playbooks-test -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
helmrelease=$(kubectl -n mission-control exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::HelmRelease name=echo-server -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')

echo $kustomization

# Reconcile,suspend, resume
echo "Running flux-suspend ==================="
runPlaybookNoEditMain "flux-suspend" config=$helmrelease
echo "Verifying flux-suspend ================="
if [[ $(flux get hr -n playbooks-test --no-header | awk '{print $3}') != "True" ]]; then
  echo "Error: Flux suspend playbook failed"
  exit 1
fi


echo "Running flux-resume =================="
runPlaybookNoEditMain "flux-resume" config=$helmrelease
echo "Verifying flux-resume =================="
if [[ $(flux get hr -n playbooks-test --no-header | awk '{print $3}') != "False" ]]; then
  echo "Error: Flux resume playbook failed"
  exit 1
fi

runPlaybookNoEditMain "flux-reconcile" config=$helmrelease

# Helm related playbooks

echo "Running Helm update-values and version =================="
echo '{"yamlInput": "replicaCount: 3", "commit_message": "From local helm playbook test"}' > /tmp/params-update-helm-values
runPlaybook "update-helm-values" config="$helmrelease" -p /tmp/params-update-helm-values
rm /tmp/params-update-helm-values

runPlaybook "update-helm-chart-version" config="$helmrelease" version="0.5.0" commit_message="Test.from.local.helm"

echo "Verifying Helm update-values and version ================"
git clone git@github.com:flanksource/flux-playbooks-test.git /tmp/playbooks-test

if [[ $(cat /tmp/playbooks-test/helm-release.yml | yq 'select(.kind=="HelmRelease").spec.values.replicaCount') != '3' ]]; then
  echo "Error: Update helm values playbook failed"
  exit 1
fi

if [[ $(cat /tmp/playbooks-test/helm-release.yml | yq 'select(.kind=="HelmRelease").spec.chart.spec.version') != '0.5.0' ]]; then
  echo "Error: Update helm values playbook failed"
  exit 1
fi

# Reset source repo
echo "Resetting to last stable commit"
cd /tmp/playbooks-test && git reset --hard $REPO_ORIGINAL_COMMIT && git push -f origin main
cd $fileroot
rm -rf /tmp/playbooks-test

# Create deployment
namespace=$(kubectl -n mission-control exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::Namespace name=playbooks-test -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
runPlaybookNoEditMain "kustomize-create-deployment" config=$namespace name="nginx" image="nginx:latest"

# Create namespace
runPlaybookNoEditMain "kustomize-create-namespace" name="playbook-test-ns" config=$kustomization

git clone git@github.com:flanksource/flux-playbooks-test.git /tmp/playbooks-test
if [[ $(cat /tmp/playbooks-test/kustomization.yaml | yq '.resources | contains(["deploy-nginx.yaml"])') != 'true' ]]; then
  echo "Error: Create deployment playbook failed"
  exit 1
fi

if [[ $(cat /tmp/playbooks-test/deploy-nginx.yaml | yq '.spec.template.spec.containers[0].image') != 'nginx:latest' ]]; then
  echo "Error: Create deployment playbook failed"
  exit 1
fi

if [[ $(cat /tmp/playbooks-test/kustomization.yaml | yq '.resources | contains(["namespaces/playbook-test-ns"])') != 'true' ]]; then
  echo "Error: Create namespace playbook failed"
  exit 1
fi

if [[ $(cat /tmp/playbooks-test/namespaces/playbook-test-ns/kustomization.yaml | yq '.resources | contains(["namespace.yaml"])') != 'true' ]]; then
  echo "Error: Create namespace playbook failed"
  exit 1
fi

if [[ $(cat /tmp/playbooks-test/namespaces/playbook-test-ns/namespace.yaml | yq '.metadata.name ') != 'playbook-test-ns' ]]; then
  echo "Error: Create namespace playbook failed"
  exit 1
fi

# Reset source repo
echo "Resetting to last stable commit"
cd /tmp/playbooks-test && git reset --hard $REPO_ORIGINAL_COMMIT && git push -f origin main
cd $fileroot
rm -rf /tmp/playbooks-test

# Namespace related playbooks
role=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::ClusterRole name=view -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
#runPlaybook "flux-request-namespace-access" delay="4h" role=$role config=$namespace

exit 0

#runPlaybook "kustomize-edit" config=$kustomization 
# runPlaybook "kustomize-debug-git" config=$kustomization


ns=$(incident-commander catalog query type=Kubernetes::Namespace  name=$name  --log-to-stderr -f json -w 5m | jq -r '.configs[0].id')

if [[ "$ns" == "" ]]; then
  echo "Failed to find new namespace"
fi
