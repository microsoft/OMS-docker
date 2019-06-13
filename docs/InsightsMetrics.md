
## InsightsMetrics - Azure Monitor for containers
Following metrics are collected by default by the Azure monitor for Containers agent

 - Metrics are collected every 60 secs (1 min) into `InsightsMetrics` table
 - `Tags` field will have tags/dimensions for the corresponding metric
 - `Computer` field will give the computer/host of the agent thats collecting the metric
	 - Computer/host for which the metric is applicable will be available as `hostName`in the `Tags` field

### Disk metrics

|Name|Namespace|Description|
|--|--|--|
| `used`|`container.azm.ms/disk`  |[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/disk)|
|`free`|`container.azm.ms/disk`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/disk)|
|`used_percent`|`container.azm.ms/disk`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/disk)

### Disk IO metrics

|Name|Namespace|Description|
|--|--|--|
| `reads`|`container.azm.ms/diskio`  |[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
|`read_bytes`|`container.azm.ms/diskio`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
|`read_time`|`container.azm.ms/diskio`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
| `writes`|`container.azm.ms/diskio`  |[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
|`write_bytes`|`container.azm.ms/diskio`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
|`write_time`|`container.azm.ms/diskio`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
|`io_time`|`container.azm.ms/diskio`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|
|`iops_in_progress`|`container.azm.ms/diskio`|[more info](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/diskio)|

### Host network metrics
|Name|Namespace|Description|
|--|--|--|
| `bytes_sent`|`container.azm.ms/net`  |[more info](https://github.com/influxdata/telegraf/blob/master/plugins/inputs/net/NET_README.md)|
|`bytes_received`|`container.azm.ms/net`|[more info](https://github.com/influxdata/telegraf/blob/master/plugins/inputs/net/NET_README.md)|
|`err_in`|`container.azm.ms/net`|[more info](https://github.com/influxdata/telegraf/blob/master/plugins/inputs/net/NET_README.md)|
| `err_out`|`container.azm.ms/net`  |[more info](https://github.com/influxdata/telegraf/blob/master/plugins/inputs/net/NET_README.md)|

### Kubelet metrics
|Name|Namespace|Description|
|--|--|--|
| `kubelet_docker_operations`|`container.azm.ms/prometheus`  |Cumulative number of Docker operations by operation type|
|`kubelet_docker_operations_errors`|`container.azm.ms/prometheus`|Cumulative number of Docker operation errors by operation type|
