package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/mitchellh/mapstructure"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

var (
	// KeyFile is the path to the private key file used for auth
	KeyFile = flag.String("key", "/shared/data/oms.key", "Private Key File")
	// CertFile is the path to the cert used for auth
	CertFile = flag.String("cert", "/shared/data/oms.crt", "OMS Agent Certificate")
	// OMSEndpoint ingestion endpoint
	OMSEndpoint string
)

var (
	// ImageIDMap caches the container id to image mapping
	ImageIDMap map[string]string
	// NameIDMap caches the container it to Name mapping
	NameIDMap map[string]string
	// IgnoreIDSet set of  container Ids of kube-system pods
	IgnoreIDSet map[string]bool
)

var (
	// FLBLogger stream
	FLBLogger = createLogger()
	// Log method
	Log = FLBLogger.Printf
)

const containerInventoryPath = "/var/opt/microsoft/docker-cimprov/state/ContainerInventory"

// ContainerInventory represents the container info
type ContainerInventory struct {
	ElementName       string `json:"ElementName"`
	CreatedTime       string `json:"CreatedTime"`
	State             string `json:"State"`
	ExitCode          int    `json:"ExitCode"`
	StartedTime       string `json:"StartedTime"`
	FinishedTime      string `json:"FinishedTime"`
	ImageID           string `json:"ImageId"`
	Image             string `json:"Image"`
	Repository        string `json:"Repository"`
	ImageTag          string `json:"ImageTag"`
	ComposeGroup      string `json:"ComposeGroup"`
	ContainerHostname string `json:"ContainerHostname"`
	Computer          string `json:"Computer"`
	Command           string `json:"Command"`
	EnvironmentVar    string `json:"EnvironmentVar"`
	Ports             string `json:"Ports"`
	Links             string `json:"Links"`
}

// DataItem represents the object corresponding to the json that is sent by fluentbit tail plugin
type DataItem struct {
	LogEntry          string `json:"LogEntry"`
	LogEntrySource    string `json:"LogEntrySource"`
	LogEntryTimeStamp string `json:"LogEntryTimeStamp"`
	ID                string `json:"Id"`
	Image             string `json:"Image"`
	Name              string `json:"Name"`
	SourceSystem      string `json:"SourceSystem"`
	Computer          string `json:"Computer"`
}

// ContainerLogBlob represents the object corresponding to the payload that is sent to the ODS end point
type ContainerLogBlob struct {
	DataType  string     `json:"DataType"`
	IPName    string     `json:"IPName"`
	DataItems []DataItem `json:"DataItems"`
}

func populateMaps() {
	files, err := ioutil.ReadDir(containerInventoryPath)

	if err != nil {
		Log("error when reading container inventory")
		log.Fatal(err.Error())
	}

	for _, file := range files {
		fullPath := fmt.Sprintf("%s/%s", containerInventoryPath, file.Name())
		fileContent, err := ioutil.ReadFile(fullPath)
		if err != nil {
			Log("Error reading file content %s", fullPath)
			log.Fatal(err)
		}
		var containerInventory ContainerInventory
		unmarshallErr := json.Unmarshal(fileContent, &containerInventory)

		if unmarshallErr != nil {
			Log("Unmarshall error when reading file %s", fullPath)
			log.Fatal(unmarshallErr)
		}

		ImageIDMap[file.Name()] = containerInventory.Image
		NameIDMap[file.Name()] = containerInventory.ElementName
	}
}

func createLogger() *log.Logger {
	logfile, err := os.Create(filepath.Join("/shared/data", fmt.Sprintf("fluent-bit-runtime_%s.log", time.Now().Format("2006-01-02T15-04-05"))))
	if err != nil {
		panic(err.Error())
	}

	return log.New(logfile, "", 0)
}

func initMaps() {
	ImageIDMap = make(map[string]string)
	NameIDMap = make(map[string]string)

	populateMaps()

	for range time.Tick(time.Second * 60) {
		populateMaps()
	}
}

func updateIgnoreContainerIds() {
	IgnoreIDSet = make(map[string]bool)

	updateKubeSystemContainerIDs()

	for range time.Tick(time.Second * 300) {
		updateKubeSystemContainerIDs()
	}
}

func updateKubeSystemContainerIDs() {

	if strings.Compare(os.Getenv("DISABLE_KUBE_SYSTEM_LOG_COLLECTION"), "true") != 0 {
		Log("Kube System Log Collection is ENABLED.")
		return
	}

	Log("Kube System Log Collection is DISABLED. Collecting containerIds to drop their records")
	config, err := rest.InClusterConfig()
	if err != nil {
		Log("Error getting config")
		panic(err.Error())
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		Log("Error getting clientset")
		panic(err.Error())
	}

	pods, err := clientset.CoreV1().Pods("kube-system").List(metav1.ListOptions{})
	if err != nil {
		Log("Error getting pods")
		panic(err.Error())
	}

	for _, pod := range pods.Items {
		for _, status := range pod.Status.ContainerStatuses {
			IgnoreIDSet[status.ContainerID[9:len(status.ContainerID)]] = true
		}
	}
}

// PostDataHelper sends data to the OMS endpoint
func PostDataHelper(tailPluginRecords []map[interface{}]interface{}) {

	var dataItems []DataItem
	for _, record := range tailPluginRecords {

		id := toString(record["Id"])

		// if Id is in the list of Ids to drop  (Kube-system containers) continue
		if containsKey(IgnoreIDSet, id) {
			Log("Dropping record with id %s since it is a kube-system log entry and log collection is disabled for KubeSystem", id)
			continue
		}

		var dataItem DataItem
		stringMap := make(map[string]string)

		// convert map[interface{}]interface{} to  map[string]string
		for key, value := range record {
			strKey := fmt.Sprintf("%v", key)
			strValue := toString(value)
			stringMap[strKey] = strValue
		}

		// TODO : dilipr check for the existence of the key and update the map
		stringMap["Image"] = ImageIDMap[id]
		stringMap["Name"] = NameIDMap[id]
		mapstructure.Decode(stringMap, &dataItem)
		dataItems = append(dataItems, dataItem)
	}

	logEntry := ContainerLogBlob{
		DataType:  "CONTAINER_LOG_BLOB",
		IPName:    "Containers",
		DataItems: dataItems}

	marshalled, err := json.Marshal(logEntry)

	cert, err := tls.LoadX509KeyPair(*CertFile, *KeyFile)
	if err != nil {
		Log("Error when loading cert")
	}

	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
	}

	tlsConfig.BuildNameToCertificate()
	transport := &http.Transport{TLSClientConfig: tlsConfig}

	client := &http.Client{Transport: transport}
	req, _ := http.NewRequest("POST", OMSEndpoint, bytes.NewBuffer(marshalled))
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		Log("Error when sending request")
	}

	statusCode := resp.Status
	Log("Status Code: %s", statusCode)
}

func containsKey(currentMap map[string]bool, key string) bool {
	_, c := currentMap[key]
	return c
}

func readConfig() {
	workspaceIDFile := "/shared/data/workspaceId"
	workspaceID, err := ioutil.ReadFile(workspaceIDFile)
	if err != nil {
		Log("Error when reading workspaceId file")
	}

	OMSEndpoint = fmt.Sprintf("https://%s.ods.opinsights.azure.com/OperationalData.svc/PostJsonDataItems", strings.TrimSpace(string(workspaceID)))
	Log("OMSEndpoint %s \n\n", OMSEndpoint)
}

func toString(s interface{}) string {
	value := s.([]uint8)
	return string([]byte(value[:]))
}
