# How to set up alerts for performance problems in Azure Monitor for containers

Azure Monitor for containers monitors the performance of container workloads deployed to either Azure Container Instances or managed Kubernetes clusters hosted on Azure Kubernetes Service (AKS). To enable monitoring, you will need to first create alert rules using kusto queries. This article will provide information on how to create alert rules with sample alerting queries.

### How to create alert rules 
For step by step procedures on how to create alert rules, please go [here.](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-alerts#create-alert-rule)

### Alerting situations (Queries):
- [Node CPU and memory utilization exceeds your defined threshold](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-alerts#resource-utilization-log-search-queries)
- [Pod CPU or memory utilization within a controller exceeds your defined threshold as compared to the set limit](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-alerts#resource-utilization-log-search-queries)
- ["NotReady" Status Node counts](NotReadyQuery.md)
- [Pod phase counts (Failed, Pending, Unknown, Running, Succeeded)](PendingPodCount.md)

#### *Note on the queries*
- Make sure to change the cluster name to your cluster. 
```let clusterName = 'YOURCLUSTERNAME';```

- *Alert by Pod Phases:*  To alert on certain pod phases such as Pending, Failed, or Unknown, you will need to modify the last line of the query in [Pod phase counts](PendingPodCount.md). 
 For example) Alert on FailedCount
```| summarize AggregatedValue = avg(FailedCount) by bin(TimeGenerated, trendBinSize) ```

- *View in Chart*: If you want to see what the query does in the chart, go to Log Analytics and replace the last line that starts with ```| summarize ...``` to ```| render timechart```. Also you can change the start date time and duration by modifying the following: 
```
let startDateTime = startofday(ago(14d));
let trendBinSize = 1d;
```
