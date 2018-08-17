package main

import "github.com/fluent/fluent-bit-go/output"
import (
	"fmt"
	"unsafe"
	"C"
	"flag"
	"io/ioutil"
	"log"
	"encoding/json"
	"crypto/tls"
	"net/http"
	"bytes"
	"github.com/mitchellh/mapstructure"
)

var (
	// ImageIDMap caches the container id to image mapping
	ImageIDMap map[string]string

	// NameIDMap caches the container it to Name mapping
	NameIDMap map[string]string
	
	// KeyFile is the path to the private key file used for auth
	KeyFile = flag.String("key", "/etc/opt/microsoft/omsagent/6bb1e963-b08c-43a8-b708-1628305e964a/certs/oms.key", "Private Key File")

	// CertFile is the path to the cert used for auth
	CertFile = flag.String("cert", "/etc/opt/microsoft/omsagent/6bb1e963-b08c-43a8-b708-1628305e964a/certs/oms.crt", "OMS Agent Certificate")
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

//export FLBPluginRegister
func FLBPluginRegister(ctx unsafe.Pointer) int {
	return output.FLBPluginRegister(ctx, "oms", "Stdout GO!")
}

//export FLBPluginInit
// (fluentbit will call this)
// ctx (context) pointer to fluentbit context (state/ c code)
func FLBPluginInit(ctx unsafe.Pointer) int {
	// Example to retrieve an optional configuration parameter
	param := output.FLBPluginConfigKey(ctx, "param")
	fmt.Printf("[flb-go] plugin parameter = '%s'\n", param)
	populateMaps()
	return output.FLB_OK
}

//export FLBPluginFlush
func FLBPluginFlush(data unsafe.Pointer, length C.int, tag *C.char) int {
	var count int
	var ret int
	var record map[interface{}]interface{}
	var records []map[interface{}]interface{}

	// Create Fluent Bit decoder
	dec := output.NewDecoder(data, int(length))

	// Iterate Records
	count = 0
	for {
		// Extract Record
		ret, _, record = output.GetRecord(dec)
		if ret != 0 {
			break
		}
		records = append(records,record)
		count++
	}
	fmt.Printf("Incoming Records Length %d \n", len(records))
	PostDataHelper(records)

	return output.FLB_OK
}

//export FLBPluginExit
func FLBPluginExit() int {
	return output.FLB_OK
}

func populateMaps() {
	files, err := ioutil.ReadDir(containerInventoryPath)

	ImageIDMap = make(map[string]string)
	NameIDMap = make(map[string]string)

	if err != nil {
		log.Fatal(err)
	}

	for _, file := range files {
		fullPath := fmt.Sprintf("%s/%s", containerInventoryPath, file.Name())
		fileContent, err := ioutil.ReadFile(fullPath)
		if err != nil {
			log.Fatal(err)
		}
		var containerInventory ContainerInventory
		unmarshallErr := json.Unmarshal(fileContent, &containerInventory)

		if unmarshallErr != nil {
			log.Fatal(unmarshallErr)
		}

		ImageIDMap[file.Name()] = containerInventory.Image
		NameIDMap[file.Name()] = containerInventory.ElementName
	}
}

func main() {
}

// PostDataHelper method helps in Posting Data to the ODS endpoint
func PostDataHelper(tailPluginRecords []map[interface{}]interface{}) {
	var dataItems []DataItem

	for _, record := range tailPluginRecords {
		var dataItem DataItem
		stringMap := make(map[string]string)

		// convert map[interface{}]interface{} to  map[string]string
		for key, value := range record {
			strKey := fmt.Sprintf("%v", key)
			strValue := toString(value)
			stringMap[strKey] = strValue
		}
		
		//idValue := record["Id"].([]uint8)
		//id := string([]byte(idValue[:]))
		//id := string([]byte(stringMap["Id"][:]))
		id := toString(record["Id"])
//		fmt.Printf("Looked up Id : %s\n", id)
		// check for the existence of the key and update the map
		stringMap["Image"] = ImageIDMap[id]
		stringMap["Name"] = NameIDMap[id]
		//fmt.Printf("Image %s <---> Name %s\n", stringMap["Image"], stringMap["Name"])
		mapstructure.Decode(stringMap, &dataItem)
		dataItems = append(dataItems, dataItem)
//		fmt.Printf("Record LogEntry %s \n", stringMap["LogEntry"])
//		fmt.Printf("DataItem LogEntry %s \n", dataItem.LogEntry)
//		fmt.Printf("DataItem LogEntryTimeStamp %s \n", dataItem.LogEntryTimeStamp)
//		fmt.Printf("DataItem LogEntrySource %s \n", dataItem.LogEntrySource)
//		fmt.Printf("DataItem Image %s \n", dataItem.Image)
//		fmt.Printf("DataItem Name %s \n", dataItem.Name)
	}
	

	logEntry := ContainerLogBlob{
		DataType:  "CONTAINER_LOG_BLOB",
		IPName:    "Containers",
		DataItems: dataItems}

//	fmt.Printf("ContainerLogBlob DataItems %d", len(logEntry.DataItems))
//	fmt.Printf("ContainerLogBlob IPName %s", logEntry.IPName)
//	fmt.Printf("ContainerLogBlob DataType %s", logEntry.DataType)
	marshalled, err := json.Marshal(logEntry)

	cert, err := tls.LoadX509KeyPair(*CertFile, *KeyFile)
	if err != nil {
		log.Fatal(err)
	}

	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
	}

	tlsConfig.BuildNameToCertificate()
	transport := &http.Transport{TLSClientConfig: tlsConfig}

	url := "https://6bb1e963-b08c-43a8-b708-1628305e964a.ods.opinsights.azure.com/OperationalData.svc/PostJsonDataItems"
	client := &http.Client{Transport: transport}
	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(marshalled))
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println(err)
	}

	statusCode := resp.Status
	fmt.Println(statusCode)	
}

func toString(s interface{}) string{
	value := s.([]uint8)
	return string([]byte(value[:]))
}
