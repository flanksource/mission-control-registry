LOCALBIN ?= $(shell pwd)/.bin

$(LOCALBIN):
	mkdir -p .bin

.PHONY: values.schema.json
values.schema.json: .bin/helm-schema
	.bin/helm-schema -r -f values.yaml

.PHONY: chart
chart: values.schema.json  README.md

.PHONY: README.md
README.md: .bin/helm-docs
	.bin/helm-docs   -t README.md.tpl

.bin/helm-docs:
	deps install --bin-dir $(LOCALBIN) norwoodj/helm-docs@v1.14.2

.bin/helm-schema:
	deps install --bin-dir $(LOCALBIN) dadav/helm-schema@0.18.1


.PHONY: lint
lint: chart
	ct lint --charts .
