```
let endDateTime = now();
let startDateTime = ago(1h);
let trendBinSize = 1m;
let clusterName = 'YOURCLUSTERNAME'; //can remove references for this from the query to show data for all clusters
KubeNodeInventory
| where TimeGenerated < endDateTime
| where TimeGenerated >= startDateTime
| where ClusterName == clusterName
| distinct ClusterName, TimeGenerated
| summarize ClusterSnapshotCount = count() by Timestamp = bin(TimeGenerated, trendBinSize), ClusterName
| join hint.strategy=broadcast (
    KubeNodeInventory
    | where TimeGenerated < endDateTime
    | where TimeGenerated >= startDateTime
    | summarize TotalCount = count(), ReadyCount = sumif(1, Status contains ('Ready'))
                by ClusterName, Timestamp = bin(TimeGenerated, trendBinSize)
    | extend NotReadyCount = TotalCount - ReadyCount
) on ClusterName, Timestamp
| project Timestamp,
          ReadyCount = todouble(ReadyCount) / ClusterSnapshotCount,
          NotReadyCount = todouble(NotReadyCount) / ClusterSnapshotCount
| render timechart
```
