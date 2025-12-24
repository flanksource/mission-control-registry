package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	flanksourceCtx "github.com/flanksource/commons-db/context"
	"github.com/flanksource/commons-db/kubernetes"
	"github.com/flanksource/commons-test/helm"
	k8stest "github.com/flanksource/commons-test/kubernetes"
	"github.com/flanksource/commons-test/mission_control"
	"github.com/flanksource/commons/http"
	commonsLogger "github.com/flanksource/commons/logger"
	_ "github.com/microsoft/go-mssqldb"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var (
	kubeconfig  string
	namespace   string
	chartPath   string
	releaseName string
	ctx         flanksourceCtx.Context
)

var logger commonsLogger.Logger
var k8s *kubernetes.Client
var db *sql.DB
var connectionString string

func findParentDir(dir string) string {
	currentDir, _ := os.Getwd()

	for {

		if _, ok := os.Stat(filepath.Join(currentDir, dir)); ok == nil {
			return filepath.Join(currentDir, dir)
		}
		if _, ok := os.Stat(filepath.Join(currentDir, ".git")); ok == nil {
			// Reached the git root, stop searching
			return currentDir
		}
		currentDir = filepath.Dir(currentDir)
	}
	return ""
}

func TestHelm(t *testing.T) {
	logger = commonsLogger.NewWithWriter(GinkgoWriter)
	commonsLogger.Use(GinkgoWriter)
	RegisterFailHandler(Fail)
	RunSpecs(t, "MSSQL Helm Chart Suite")
}

var mcInstance *mission_control.MissionControl
var mcChart *helm.HelmChart

var mcStopChan, configDBStopChan, mssqlStopChan chan struct{}
var _ = BeforeSuite(func() {

	// Get environment variables or use defaults
	kubeconfig = os.Getenv("KUBECONFIG")
	if kubeconfig == "" {
		home := os.Getenv("HOME")
		kubeconfig = filepath.Join(home, ".kube", "config")
	}

	namespace = os.Getenv("TEST_NAMESPACE")
	if namespace == "" {
		namespace = "mission-control"
	}

	chartPath = findParentDir("chart")

	releaseName = "mssql-test"

	logger.Infof("KUBECONFIG=%s ns=%s, chart=%s", kubeconfig, namespace, chartPath)

	if stat, err := os.Stat(kubeconfig); err != nil || stat.IsDir() {
		path, _ := filepath.Abs(kubeconfig)
		Skip(fmt.Sprintf("KUBECONFIG %s is not valid, skipping helm tests", path))
	}

	ctx = flanksourceCtx.New().
		WithNamespace("mission-control")

	var err error
	k8s, err = ctx.LocalKubernetes(kubeconfig)
	Expect(err).NotTo(HaveOccurred())

	By("Installing Mission Control")
	mcChart = helm.NewHelmChart(ctx, "flanksource/mission-control").
		Repository("flanksource", "https://flanksource.github.io/charts").
		Release("mission-control").Namespace("mission-control")

	Expect(mcChart.
		WaitFor(time.Minute * 5).
		ForceConflicts().
		Values(map[string]any{
			"global": map[string]any{
				"ui": map[string]any{
					"host": "mission-control.cluster.local",
				},
			},
			"authProvider": "basic",
			"htpasswd": map[string]any{
				"create": true,
			},
			"flanksource-ui": map[string]any{"enabled": false},
			"kratos":         map[string]any{"enabled": false},
			"ingress":        map[string]any{"enabled": false},
			"config-db": map[string]any{
				"logLevel": "-vvv",
				"properties": map[string]any{
					"log.exclusions": true,
				},
			},
			"logLevel": "-vvv",
		}).
		InstallOrUpgrade()).NotTo(HaveOccurred())

	adminPasswordSecret, err := k8s.CoreV1().Secrets(namespace).Get(ctx, "mission-control-admin-password", v1.GetOptions{})
	Expect(err).NotTo(HaveOccurred(), "Failed to get Mission Control admin password secret")
	adminPassword := string(adminPasswordSecret.Data["password"])
	Expect(adminPassword).NotTo(BeEmpty(), "Mission Control admin password should not be empty")

	// Port forward to mission-control pod
	var mcLocalPort int
	mcLocalPort, mcStopChan, err = k8stest.PortForwardPod(ctx, k8s, kubeconfig, namespace, "app.kubernetes.io/name=mission-control", 8080)
	Expect(err).NotTo(HaveOccurred(), "Failed to port forward to Mission Control pod")

	// Port forward to config-db pod
	var configDBLocalPort int
	configDBLocalPort, configDBStopChan, err = k8stest.PortForwardPod(ctx, k8s, kubeconfig, namespace, "app.kubernetes.io/name=config-db", 8080)
	Expect(err).NotTo(HaveOccurred(), "Failed to port forward to Config DB pod")

	// Initialize Mission Control client, get credentianls and serviceIP from deployed chart.
	mcInstance = &mission_control.MissionControl{
		HTTP:     http.NewClient().BaseURL(fmt.Sprintf("http://localhost:%d", mcLocalPort)).Auth("admin@local", adminPassword),
		Username: "admin@local",
		Password: adminPassword,
		ConfigDB: http.NewClient().BaseURL(fmt.Sprintf("http://localhost:%d", configDBLocalPort)).Auth("admin@local", adminPassword),
	}

	db, connectionString, err = setupSqlServer()
	Expect(err).NotTo(HaveOccurred())

	dbName := ""
	if err := db.QueryRow("SELECT DB_NAME()").Scan(&dbName); err != nil {
		Expect(err).NotTo(HaveOccurred(), "Failed to query database name")
	}
	Expect(dbName).To(Equal("master"), "Expected database name to be 'master'")

})

var _ = AfterSuite(func() {
	if mcStopChan != nil {
		close(mcStopChan)
	}
	if configDBStopChan != nil {
		close(configDBStopChan)
	}
})

func setupSqlServer() (*sql.DB, string, error) {
	result, err := k8s.ApplyFile(context.Background(), "sqlserver.yaml")
	Expect(err).NotTo(HaveOccurred())
	logger.Infof(result.Pretty().ANSI())
	Expect(err).NotTo(HaveOccurred(), "Failed to deploy test SQL Server: %s", result)

	mssqlNs := "default"
	if err := k8s.WaitForPod(context.Background(), mssqlNs, "mssql-0", time.Minute*5); err != nil {
		return nil, "", fmt.Errorf("SQL Server pod did not become ready in time: %v", err)
	}

	pod, err := k8s.CoreV1().Pods(mssqlNs).Get(context.TODO(), "mssql-0", v1.GetOptions{})
	Expect(err).NotTo(HaveOccurred(), "Failed to get SQL Server pod: %s", err)
	Expect(pod).NotTo(BeNil(), "Expected SQL Server pod to be found")
	Expect(pod.Status.PodIP).NotTo(BeEmpty(), "Expected SQL Server pod to have a valid IP address")

	var mssqlPort int
	mssqlPort, mssqlStopChan, err = k8stest.PortForwardPod(ctx, k8s, kubeconfig, mssqlNs, "app=mssql", 1433)
	Expect(err).NotTo(HaveOccurred(), "Failed to port forward to MSSQL pod")

	connectionString = fmt.Sprintf("sqlserver://sa:Your_password123@%s:1433?database=master;encrypt=disable;TrustServerCertificate=true",
		pod.Status.PodIP)

	logger.Infof("Connecting to SQL Server with connection string: %s", connectionString)

	connStringLocal := fmt.Sprintf("sqlserver://sa:Your_password123@localhost:%d?database=master;encrypt=disable;TrustServerCertificate=true",
		mssqlPort)

	db, err := sql.Open("sqlserver", connStringLocal)
	if err != nil {
		return nil, "", fmt.Errorf("Failed to open SQL Server connection: %v", err)
	}
	err = db.Ping()
	Expect(err).NotTo(HaveOccurred())

	testDataSQL, err := os.ReadFile("./test-data.sql")
	Expect(err).NotTo(HaveOccurred())

	_, err = db.Exec(string(testDataSQL))
	Expect(err).NotTo(HaveOccurred())

	time.Sleep(15 * time.Second)
	return db, connectionString, nil
}
