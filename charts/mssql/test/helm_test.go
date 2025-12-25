package main

import (
	"github.com/flanksource/clicky"
	"github.com/flanksource/commons-test/helm"
	"github.com/flanksource/commons-test/mission_control"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

// Helm tests using fluent interface from commons
var _ = Describe("MSSQL Bundle", Ordered, func() {

	Context("Mission Control", func() {
		It("Is Installed", func() {
			status, err := mcChart.GetStatus()
			if status != nil {
				By(status.Pretty().ANSI())
			}
			Expect(err).NotTo(HaveOccurred())
			Expect(status.Info.Status).To(Equal("deployed"))
			Expect(mcInstance).NotTo(BeNil())
		})

	})

	Context("SQL Server Bundle", Ordered, func() {
		var mssqlChart *helm.HelmChart

		It("Can be Installed", func() {
			mssqlChart = helm.NewHelmChart(ctx, "..").
				Release("mssql-bundle").
				Namespace("mission-control").
				ForceConflicts().
				SetValue("connectionName", "").
				SetValue("url", connectionString)
			Expect(mssqlChart.InstallOrUpgrade()).NotTo(HaveOccurred())
			status, err := mssqlChart.GetStatus()
			Expect(err).NotTo(HaveOccurred())
			Expect(status.Info.Status).To(Equal("deployed"))
		})

		It("Runs the main scraper successfully", func() {
			mainScraper, err := k8s.Get(ctx, "ScrapeConfig", "mission-control", "mssql-scraper")
			Expect(err).NotTo(HaveOccurred())
			Expect(mainScraper).NotTo(BeNil())

			resp, err := mcInstance.GetScraper(string(mainScraper.GetUID())).Run()
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.Errors).To(BeEmpty(), "Expected no errors from scraper run")
			By(clicky.MustFormat(resp.Summary))
		})

		It("Runs the incremental scraper successfully", func() {
			incrementalScraper, err := k8s.Get(ctx, "ScrapeConfig", "mission-control", "mssql-scraper-incremental")
			Expect(err).NotTo(HaveOccurred())
			Expect(incrementalScraper).NotTo(BeNil())

			resp, err := mcInstance.GetScraper(string(incrementalScraper.GetUID())).Run()
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.Errors).To(BeEmpty(), "Expected no errors from scraper run")
			By(clicky.MustFormat(resp.Summary))
		})

		It("Creates MSSQL:Server config items", func() {
			servers, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::Server"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(servers).NotTo(BeEmpty(), "Expected at least one MSSQL::Server config item")
			for _, s := range servers {
				By("Found server: " + s.Name)
			}
		})

		It("Creates MSSQL:Database config items", func() {
			databases, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::Database"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(databases).NotTo(BeEmpty(), "Expected at least one MSSQL::Database config item")
			for _, db := range databases {
				By("Found database: " + db.Name)
			}
		})

		It("Creates changes after running agent job", func() {
			agentJobs, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::AgentJob"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(agentJobs).NotTo(BeEmpty(), "Expected at least one MSSQL::AgentJob config item")
			for _, aj := range agentJobs {
				By("Found agent job: " + aj.Name)
			}

			req := mission_control.CatalogChangesSearchRequest{ConfigType: "MSSQL::AgentJob"}
			resp, err := mcInstance.SearchCatalogChanges(req)
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.Changes).NotTo(BeEmpty(), "Expected at least one change for MSSQL::AgentJob")
		})
	})
})
