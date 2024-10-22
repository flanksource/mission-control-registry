# Config db run more than once for all relationships to form
# system user's email in people table should be set for git
# Run incident-commander in serve mode for git connection to by synced
# All of these should be run in AWS Cluster pointed in kubeconfig

set -ex
function runPlaybook() {
  all_args=("$@")
  echo "Running playbook $1 ${all_args[@]:1}"
  helm template ./ --set git.connection="connection://mission-control/github" | yq ea " . | select(.metadata.name == \"$1\")" | incident-commander playbook run -v=5  /dev/stdin ${all_args[@]:1}

  if [[ "$?" != "0" ]]; then
    exit 1
  fi
}

name=flux-$(date "+%H%M%S")
kustomization=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::Kustomization name=aws-demo-infra -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')

echo $kustomization

# Helm related playbooks
helmrelease=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::HelmRelease name=mission-control-prometheus -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')

echo '{"yamlInput": "foo: bar", "commit_message": "From local helm playbook test"}' > /tmp/params-update-helm-values
#runPlaybook "update-helm-values" config="$helmrelease" -p /tmp/params-update-helm-values
#runPlaybook "update-helm-chart-version" config="$helmrelease" version="new-version" commit_message="Test.from.local.helm"

# Namespace related playbooks
namespace=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::Namespace name=httpbin -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
role=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::ClusterRole name=view -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
#runPlaybook "flux-request-namespace-access" delay="4h" role=$role config=$namespace

# Reconcile,suspend, resume
#runPlaybook "flux-suspend" config=$helmrelease
#runPlaybook "flux-resume" config=$helmrelease
#runPlaybook "flux-reconcile" config=$helmrelease

exit 0

#runPlaybook "kustomize-edit" config=$kustomization 
# runPlaybook "kustomize-debug-git" config=$kustomization


ns=$(incident-commander catalog query type=Kubernetes::Namespace  name=$name  --log-to-stderr -f json -w 5m | jq -r '.configs[0].id')

if [[ "$ns" == "" ]]; then
  echo "Failed to find new namespace"
fi
