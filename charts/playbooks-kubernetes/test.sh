function runPlaybook() {
  all_args=("$@")
  echo "Running playbook $1 ${all_args[@]:1}"
  helm template ./  | yq ea " . | select(.metadata.name == \"$1\")" | incident-commander playbook run -v=2 -f json -o run-$1.json /dev/stdin ${all_args[@]:1}
}


name=podinfo-$(date  "+%H%M%S")
ns=$(kubectl get ns default -o json  | jq -r '.metadata.uid')

runPlaybook "kubernetes-create-deployment" config=$ns  name=$name image=stefanprodan/podinfo
deployment=$(kubectl get deployment -n default $name -o json  | jq -r '.metadata.uid')


incident-commander catalog query namespace:default type=Kubernetes::Deployment config=$name

runPlaybook "kubernetes-restart" config=$deployment
runPlaybook "kubernetes-scale" config=$deployment replicas=1
runPlaybook "kubernetes-update-resources" config=$deployment cpu_request=10m
runPlaybook "kubernetes-logs" config=$deployment since=5m lines=1
runPlaybook "kubernetes-logs" config=$deployment since=5m lines=1 jsonLogs=true
runPlaybook "kubernetes-update-image" config=$deployment image=stefanprodan/podinfo:v6.7.0
runPlaybook "kubernetes-ignore-changes" config=$deployment severity=info
runPlaybook "kubernetes-delete" config=$deployment
