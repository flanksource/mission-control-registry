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
			logger.Infof(clicky.MustFormat(resp.Summary))
			By(clicky.MustFormat(resp.Summary))
		})

		It("Runs the incremental scraper successfully", func() {
			incrementalScraper, err := k8s.Get(ctx, "ScrapeConfig", "mission-control", "mssql-scraper-incremental")
			Expect(err).NotTo(HaveOccurred())
			Expect(incrementalScraper).NotTo(BeNil())

			resp, err := mcInstance.GetScraper(string(incrementalScraper.GetUID())).Run()
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.Errors).To(BeEmpty(), "Expected no errors from scraper run")
			logger.Infof(clicky.MustFormat(resp.Summary))
			By(clicky.MustFormat(resp.Summary))
		})

		It("Creates MSSQL::Server config items", func() {
			servers, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::Server"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(servers).NotTo(BeEmpty(), "Expected at least one MSSQL::Server config item")
			for _, s := range servers {
				By("Found server: " + s.Name)
			}
		})

		It("Creates MSSQL::Database config items", func() {
			databases, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::Database"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(databases).NotTo(BeEmpty(), "Expected at least one MSSQL::Database config item")
			for _, db := range databases {
				By("Found database: " + db.Name)
			}
		})

		It("Creates MSSQL::Logon config items", func() {
			logons, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::Logon"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(logons).NotTo(BeEmpty(), "Expected at least one MSSQL::Logon config item")

			expectedLogons := []string{"TestUser", "AdminUser", "ReportUser", "AppServiceUser"}
			foundLogons := make(map[string]bool)
			for _, l := range logons {
				By("Found logon: " + l.Name)
				foundLogons[l.Name] = true
			}

			for _, expected := range expectedLogons {
				Expect(foundLogons).To(HaveKey(expected), "Expected to find logon: "+expected)
			}
		})

		It("Creates MSSQL::User config items", func() {
			users, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Types: []string{"MSSQL::User"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(users).NotTo(BeEmpty(), "Expected at least one MSSQL::User config item")

			expectedUsers := []string{"DbOnlyReader", "DbOnlyWriter", "DbOnlyAdmin", "DbOnlyGuest"}
			foundUsers := make(map[string]bool)
			for _, u := range users {
				By("Found user: " + u.Name)
				foundUsers[u.Name] = true
			}

			for _, expected := range expectedUsers {
				Expect(foundUsers).To(HaveKey(expected), "Expected to find user: "+expected)
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
