.PHONY: chart
CHARTS_DIR= ./charts
chart: $(CHARTS_DIR)/*
	@for chart in $^ ; do \
    	helm package $${chart} ; \
	done
