for chart in $(ls charts); do
    helm template charts/$chart

    # kubernetes chart renders differently, if prometheus.url is set
    if [[ $chart == "kubernetes" ]]; then
        helm template --set prometheus.url='http://prometheus' charts/$chart
    fi
    # Also test kubernetes chart when kubeconfig.value is set
    if [[ $chart == "kubernetes" ]]; then
        helm template --set kubeconfig.value='kubeconfig' charts/$chart
    fi
done
