# Troubleshoot Guide for Container Health Monitoring in Azure Kuberenetes Cluster 

The table below summarizes known issues you may face while using Container Helath and Performance Monitoring feature.

| Issue | Action |
| --- | --- |
| I’m consistently seeing `No data for selected filters` message| It may take some time to establish monitoring data flow for newly created clusters. Please allow at least 30 minutes for data to appear for your cluster. Make sure you do not have any filters selected at the top of the page (such as “Node”, “Service” Etc). Make sure that “Exclude kube-system logs” checkbox is unchecked. | 
| I’m consistently getting `Error retrieving data” message` | While Azure Kubenetes cluster is set up for health and performance monitoring, a connection is established between the cluster and Azure Log Analytics workspace. Log Analytics workspace is used to store all monitoring data for you cluster. You may have lost (deleted) Log Analytics workspace or the link between Kubernetes cluster and the workspace. Please try to [opt out](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#how-to-stop-monitoring-with-container-health) of monitoring for the cluster and [onboard](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#enable-container-health-monitoring-for-a-new-cluster) again to Container Health. |
| I’m consistently getting `Error retrieving data” message` after adding monitoring addon through az cli | Due to bug in the az cli code the Container Insights solution is not onboarded as part of the --enable-addon monitoring. To resolve this issue follow the instructions in the subsequent table to onboard the Container Insights solution |

| Solution deployment | Action |
| --- | --- |
| ContainerInsights Solution | az login; az group create --name ci-deployment-rg --location <Location String>; az group deployment create --name ci-deployment --resource-group ci-deployment-rg --template-file ContainerInsights.json --parameters Parametersfile.json; For more details for resourece group template deployment via cli refer to [this documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli). |

If steps above did not help to resolve your issue you can use either of the following methods to contact us for help:
*	File a [GitHub Issue](https://github.com/Microsoft/OMS-docker/issues)
*	Email [AskCoin](mailto:askcoin@microsoft.com)
