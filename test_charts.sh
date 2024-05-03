for chart in $(ls charts); do
    helm template charts/$chart
done
