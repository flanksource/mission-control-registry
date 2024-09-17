#!/bin/bash
helm repo add flanksource https://flanksource.github.io/charts
helm repo update
helm install --devel mission-control-crds flanksource/mission-control-crds --wait

function testChart() {
    cd $1
    ct lint-and-install  --charts . --namespace default  2>&1 > stdout.log
    exitCode=$?
    cat stdout.log

    if [[ "$exitCode" != "0" ]]; then
        echo "ct-lint-and install failed"
        exit 1
    fi
    if grep "unknown field" stdout.log; then
        echo "Unknown field detected"
        exit 1
    fi
}

if [[ "$1" == "" ]]; then
    dir=$(PWD)
    for chart in $(ls charts); do
      testChart $dir/charts/$chart
    done
else
    testChart charts/$1
fi
