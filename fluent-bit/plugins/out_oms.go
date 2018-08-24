package main

import (
	"C"
	"fmt"
	"unsafe"

	"github.com/fluent/fluent-bit-go/output"
)

//FLBPluginRegister registers the plugin
func FLBPluginRegister(ctx unsafe.Pointer) int {
	return output.FLBPluginRegister(ctx, "oms", "OMS output Plugin.")
}

//FLBPluginInit initializes the plugin
// (fluentbit will call this)
// ctx (context) pointer to fluentbit context (state/ c code)
func FLBPluginInit(ctx unsafe.Pointer) int {
	populateMaps()
	return output.FLB_OK
}

//FLBPluginFlush flushes the out to a destination
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
		records = append(records, record)
		count++
	}
	fmt.Printf("Incoming Records Length %d \n", len(records))
	PostDataHelper(records)

	return output.FLB_OK
}

//FLBPluginExit exits the plugin
func FLBPluginExit() int {
	return output.FLB_OK
}

func main() {
}
