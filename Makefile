.PHONY: chart
CHARTS_DIR= ./charts
chart: escape_kubernetes_chart $(CHARTS_DIR)/*
	@for chart in $^ ; do \
    	helm package $${chart} ; \
	done

escape_kubernetes_chart:
	cat ./charts/kubernetes/edit-playbook.yml | sed 's/{{/OPENING_BRACES/g; s/}}/CLOSING_BRACES/g; s/OPENING_BRACES/{{ "{{" }}/g; s/CLOSING_BRACES/{{ "}}" }}/g' > charts/kubernetes/templates/playbook-gitops-edit-kubernetes-manfiests.yml
