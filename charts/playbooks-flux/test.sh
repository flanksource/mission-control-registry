# Config db run more than once for all relationships to form
# system user's email in people table should be set for git
# Run incident-commander in serve mode for git connection to by synced
# All of these should be run in AWS Cluster pointed in kubeconfig

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

REPO_ORIGINAL_COMMIT="eb127e4d03bbae22128d53908e4a501b17d19677"

name=flux-$(date "+%H%M%S")
kustomization=$(kubectl -n mission-control exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::Kustomization name=flux-playbooks-test -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')

echo $kustomization

# Helm related playbooks
helmrelease=$(kubectl -n mission-control exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::HelmRelease name=echo-server -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')

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
cd /tmp/playbooks-test && git reset --hard $REPO_ORIGINAL_COMMIT && git push -f origin main && cd -
rm -rf /tmp/playbooks-test



# Reconcile,suspend, resume
echo "Running flux-suspend ==================="
runPlaybook "flux-suspend" config=$helmrelease
echo "Verifying flux-suspend ================="
if [[ $(flux get hr -n playbooks-test --no-header | awk '{print $3}') != "True" ]]; then
  echo "Error: Flux suspend playbook failed"
  exit 1
fi


echo "Running flux-resume =================="
runPlaybook "flux-resume" config=$helmrelease
echo "Verifying flux-resume =================="
if [[ $(flux get hr -n playbooks-test --no-header | awk '{print $3}') != "False" ]]; then
  echo "Error: Flux resume playbook failed"
  exit 1
fi

runPlaybook "flux-reconcile" config=$helmrelease

# Namespace related playbooks
namespace=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::Namespace name=httpbin -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
role=$(kubectl exec -it deploy/mission-control -- ./incident-commander catalog query type=Kubernetes::ClusterRole name=view -w 0s --log-to-stderr -f json | rg -v INF | jq -r '.configs[0].id')
#runPlaybook "flux-request-namespace-access" delay="4h" role=$role config=$namespace

exit 0

#runPlaybook "kustomize-edit" config=$kustomization 
# runPlaybook "kustomize-debug-git" config=$kustomization


ns=$(incident-commander catalog query type=Kubernetes::Namespace  name=$name  --log-to-stderr -f json -w 5m | jq -r '.configs[0].id')

if [[ "$ns" == "" ]]; then
  echo "Failed to find new namespace"
fi
