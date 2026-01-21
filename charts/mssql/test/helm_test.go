package main

import (
	"encoding/json"
	"io"
	"time"

	"github.com/flanksource/clicky"
	"github.com/flanksource/commons-test/helm"
	"github.com/flanksource/commons-test/mission_control"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var mssqlServerConfigID string

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
				SetValue("url", connectionString).
				SetValue("playbooks.createUser.enabled", true).
				SetValue("playbooks.createUser.emailConnection", "connection://default/email").
				ForceConflicts()
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
			mssqlServerConfigID = servers[0].ID
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

		It("Creates config_access entries with correct user and role mappings", func() {
			type configAccessEntry struct {
				ConfigID       struct{ Name, Type string } `json:"config_id"`
				ExternalUserID struct{ Name string }       `json:"external_user_id"`
				ExternalRoleID struct{ Name string }       `json:"external_role_id"`
			}

			resp, err := postgrestClient.R(ctx).
				Get("/config_access?select=config_id(name,type),external_user_id(name),external_role_id(name)&deleted_at=is.null")
			Expect(err).NotTo(HaveOccurred())

			body, err := io.ReadAll(resp.Body)
			Expect(err).NotTo(HaveOccurred())
			defer resp.Body.Close()

			Expect(resp.IsOK()).To(BeTrue(), "Expected 200 OK from PostgREST, got: %d %s", resp.StatusCode, string(body))

			var entries []configAccessEntry
			err = json.Unmarshal(body, &entries)
			Expect(err).NotTo(HaveOccurred())

			type expectedMapping struct {
				ConfigName string
				ConfigType string
				UserName   string
				RoleName   string
			}

			expected := []expectedMapping{
				{"mssql", "MSSQL::Server", "TestUser", "dbcreator"},
				{"mssql", "MSSQL::Server", "TestUser", "processadmin"},
				{"mssql", "MSSQL::Server", "AdminUser", "sysadmin"},
			}

			actualMappings := make(map[string]bool)
			for _, entry := range entries {
				key := entry.ConfigID.Name + "|" + entry.ConfigID.Type + "|" + entry.ExternalUserID.Name + "|" + entry.ExternalRoleID.Name
				actualMappings[key] = true
				By("Found config_access: " + key)
			}

			for _, exp := range expected {
				key := exp.ConfigName + "|" + exp.ConfigType + "|" + exp.UserName + "|" + exp.RoleName
				Expect(actualMappings).To(HaveKey(key), "Expected config_access entry: %s", key)
			}
		})

		It("Should run the create login user playbook", func() {
			pb, err := k8s.Get(ctx, "Playbook", "mission-control", "create-mssql-login-user")
			Expect(err).NotTo(HaveOccurred())

			rb, _ := json.Marshal(map[string]any{
				"id":        pb.GetUID(),
				"config_id": mssqlServerConfigID,
				"params": map[string]any{
					"username": "NewCreatedLogin",
					"email":    "no-reply@example.com",
				},
			})

			r, err := mcInstance.HTTP.R(ctx).Header("Content-Type", "application/json").Post("/playbook/run", rb)

			Expect(err).NotTo(HaveOccurred())
			Expect(r.IsOK()).To(BeTrue())

			// Playbook run event is generated, its picked from queue and then processed
			time.Sleep(30 * time.Second)

			mainScraper, err := k8s.Get(ctx, "ScrapeConfig", "mission-control", "mssql-scraper")
			Expect(err).NotTo(HaveOccurred())
			Expect(mainScraper).NotTo(BeNil())

			resp, err := mcInstance.GetScraper(string(mainScraper.GetUID())).Run()
			Expect(err).NotTo(HaveOccurred())
			Expect(resp.Errors).To(BeEmpty(), "Expected no errors from scraper run")

			logons, err := mcInstance.QueryCatalog(mission_control.ResourceSelector{Name: "NewCreatedLogin", Types: []string{"MSSQL::Logon"}})
			Expect(err).NotTo(HaveOccurred())
			Expect(logons).NotTo(BeEmpty(), "Expected at least one MSSQL::Logon config item")

			expectedLogons := []string{"NewCreatedLogin"}
			foundLogons := make(map[string]bool)
			for _, l := range logons {
				foundLogons[l.Name] = true
			}
			for _, expected := range expectedLogons {
				Expect(foundLogons).To(HaveKey(expected), "Expected to find logon: "+expected)
			}
		})
	})
})
