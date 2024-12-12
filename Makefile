.PHONY: chart
CHARTS_DIR= ./charts
chart: $(CHARTS_DIR)/*
	@for chart in $^ ; do \
    	helm package $${chart} ; \
	done

test:
	./test_charts.sh


charts/*/values.schema.json: .bin/helm-schema
	.bin/helm-schema -r -f values.yaml

LOCALBIN ?= $(shell pwd)/.bin

$(LOCALBIN):
	mkdir -p .bin



.PHONY: chart
chart: values.schema.json  README.md


.PHONY: README.md
README.md: .bin/helm-docs
	.bin/helm-docs   -t README.md.tpl

.bin/helm-docs:
	test -s $(LOCALBIN)/helm-docs  || \
	GOBIN=$(LOCALBIN) go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest

.bin/helm-schema:
	test -s $(LOCALBIN)/helm-schema  || \
	GOBIN=$(LOCALBIN) go install github.com/dadav/helm-schema/cmd/helm-schema@latest
