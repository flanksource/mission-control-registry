set -e
function runPlaybook() {
  all_args=("$@")
  echo "Running playbook $1 ${all_args[@]:1}"
  helm template ./  | yq ea " . | select(.metadata.name == \"$1\")" | incident-commander playbook run -v=2  /dev/stdin ${all_args[@]:1}

  if [[ "$?" != "0" ]]; then
    exit 1
  fi
}


name=flux-$(date  "+%H%M%S")
kustomization=$( incident-commander catalog query type=Kubernetes::Kustomization  name=aws-demo-infra  -w 0s --log-to-stderr -f json   | jq -r '.configs[0].id')

runPlaybook "kustomize-create-namespace" Name=$name config=$kustomization
# runPlaybook "kustomize-debug-git" config=$kustomization



ns=$(incident-commander catalog query type=Kubernetes::Namespace  name=$name  --log-to-stderr -f json -w 5m | jq -r '.configs[0].id')

if [[ "$ns" == "" ]]; then
  echo "Failed to find new namespace"
fi

