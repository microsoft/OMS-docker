# Troubleshoot Guide for Container Health Monitoring in Azure Kuberenetes Cluster 



| Issue | Action |
| --- | --- |
| `No data for selected filters` | If you onboarded your cluster __< 30 mins__ ago. Please wait for a few more minutes. Please make sure that `Exclude kube-system logs` is unchecked and if your filters are set correctly |
| `Error retrieving data` | [Opt out](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#how-to-stop-monitoring-with-container-health) of monitoring and [onboard again](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#enable-container-health-monitoring-for-existing-managed-clusters) to Container Health. |


If nothing else works:

* File a [GitHub Issue](https://github.com/Microsoft/OMS-docker/issues)
* Contact us by emailing [AskCoin](mailto:askcoin@example.com)
