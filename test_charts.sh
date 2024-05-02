for chart in $(ls charts); do
    # Setting required prometheusURL
    helm template --set prometheusURL='http://prometheus' charts/$chart
done
