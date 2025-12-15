package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/flanksource/clicky"
	flanksourceCtx "github.com/flanksource/commons-db/context"
	"github.com/flanksource/commons-db/kubernetes"
	"github.com/flanksource/commons-test/helm"
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

var mcInstance *MissionControl
var mcChart *helm.HelmChart
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
	mcChart = helm.NewHelmChart(ctx, "../../../../mission-control-chart/chart/")
	// mcChart = helm.NewHelmChart(ctx, "flanksource/mission-control")
	Expect(mcChart.
		Release("mission-control").Namespace("mission-control").
		Values(map[string]interface{}{
			"global": map[string]interface{}{
				"ui": map[string]interface{}{
					"host": "mission-control.cluster.local",
				},
			},
			"authProvider": "basic",

			"htpasswd": map[string]interface{}{
				"create": true,
			},
			"ingress": map[string]interface{}{
				"enabled": true,
				"annotations": map[string]interface{}{
					"cert-manager.io/cluster-issuer": "self-signed",
				},
			},
			"config-db": map[string]interface{}{
				"logLevel": "-vvv",
			},
			"logLevel": "-vvv",
		}).
		InstallOrUpgrade()).NotTo(HaveOccurred())

	adminPasswordSecret, err := k8s.CoreV1().Secrets(namespace).Get(context.TODO(), "mission-control-admin-password", v1.GetOptions{})
	Expect(err).NotTo(HaveOccurred(), "Failed to get Mission Control admin password secret")
	adminPassword := string(adminPasswordSecret.Data["password"])
	Expect(adminPassword).NotTo(BeEmpty(), "Mission Control admin password should not be empty")
	logger.Infof(clicky.MustFormat(adminPassword))

	podIP, err := k8s.GetPodIP(ctx, namespace, "app.kubernetes.io/name=mission-control")
	Expect(err).NotTo(HaveOccurred(), "Failed to get Mission Control pod IP")

	// Initialize Mission Control client, get credentianls and serviceIP from deployed chart.
	mcInstance = &MissionControl{
		Client:   k8s,
		HTTP:     http.NewClient().BaseURL("http://"+podIP+":8080").Auth("admin@local", adminPassword),
		Username: "admin@local",
		Password: adminPassword,
	}
	podIP, err = k8s.GetPodIP(ctx, namespace, "app.kubernetes.io/name=config-db")
	Expect(err).NotTo(HaveOccurred(), "Failed to get Config DB pod IPs")
	mcInstance.ConfigDB = http.NewClient().BaseURL("http://"+podIP+":8080").Auth("admin@local", adminPassword)

	db, connectionString, err = setupSqlServer()
	Expect(err).NotTo(HaveOccurred())

	dbName := ""
	if err := db.QueryRow("SELECT DB_NAME()").Scan(&dbName); err != nil {
		Expect(err).NotTo(HaveOccurred(), "Failed to query database name")
	}
	Expect(dbName).To(Equal("master"), "Expected database name to be 'master'")

})

func setupSqlServer() (*sql.DB, string, error) {

	result, err := k8s.ApplyFile(context.Background(), "sqlserver.yaml")
	Expect(err).NotTo(HaveOccurred())
	logger.Infof(result.Pretty().ANSI())
	Expect(err).NotTo(HaveOccurred(), "Failed to deploy test SQL Server: %s", result)

	if err := mcInstance.WaitForPod(context.TODO(), namespace, "mssql-0", time.Minute*5); err != nil {
		return nil, "", fmt.Errorf("SQL Server pod did not become ready in time: %v", err)
	}

	pod, err := mcInstance.Client.CoreV1().Pods(namespace).Get(context.TODO(), "mssql-0", v1.GetOptions{})
	Expect(err).NotTo(HaveOccurred(), "Failed to get SQL Server pod: %s", err)
	Expect(pod).NotTo(BeNil(), "Expected SQL Server pod to be found")
	Expect(pod.Status.PodIP).NotTo(BeEmpty(), "Expected SQL Server pod to have a valid IP address")

	// Build connection string
	// connectionString = fmt.Sprintf("server=%s;port=1433;database=master;user id=sa;password=Your_password123;encrypt=disable",
	// 	pod.Status.PodIP)

	connectionString = fmt.Sprintf("sqlserver://sa:Your_password123@%s:1433?database=master;encrypt=disable",
		pod.Status.PodIP)

	logger.Infof("Connecting to SQL Server with connection string: %s", connectionString)

	db, err := sql.Open("sqlserver", connectionString)
	if err != nil {
		return nil, "", fmt.Errorf("Failed to open SQL Server connection: %v", err)
	}
	return db, connectionString, nil
}
