#!/bin/bash
helm repo add flanksource https://flanksource.github.io/charts
helm repo update
helm install --devel mission-control-crds flanksource/mission-control-crds --wait

if [[ "$1" == "" ]]; then
    dir=$(PWD)
    for chart in $(ls charts); do
        cd $dir/charts/$chart
      ct lint-and-install  --charts .   --namespace default
    done

else
    cd charts/$1
    ct lint-and-install  --charts . --namespace default
fi
