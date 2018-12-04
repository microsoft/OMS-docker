# Trying the Azure Monitor for containers for AKS-engine Cluster(s)

Azure Monitor for containers is a feature designed to monitor the performance of container workloads deployed to AKS-engine (old name is ACS-engine) cluster(s) hosted on Azure. Monitoring your containers is critical, especially when you're running a production cluster, at scale, with multiple applications.

Azure Monitor for containers gives you performance visibility by collecting memory and processor metrics from controllers, nodes, and containers that are available in Kubernetes through the Metrics API. Container logs are also collected. After you enable monitoring from Kubernetes clusters, these metrics and logs are automatically collected for you through a containerized version of the Log Analytics agent for Linux and stored in your Log Analytics workspace.

 Azure Monitor for containers UI experience and Data collection is pretty much same for AKS-engine cluster(s) same as Azure Kubernetes Service (AKS) cluster(s).
 For more details, see [Azure Monitor for containers](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-overview)

### Supported Kubernetes versions, Container Runtime(s) and OS Distro(s):

- Kubernetes versions, same as [AKS supported versions](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions)
- Container Runtime : Docker, Moby
- OS Distros : Ubuntu, AKS and aks-docker-engine
- Agent Nodepool : Linux
- Managed Disks
- RBAC and Non-RBAC
- Azure CNI Network

## Setting up

AKS-engine cluster(s) can be configured to use Azure Monitor for containers using HELM chart [azuremonitor-containers]https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers)

### Upgrade

You can upgrade to a newer version of [azuremonitor-containers](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) using the helm upgrade.

## What now?
Once you're set up, we'd like you to try the UI experience of [Azure Monitor for Containers](https://aka.ms/azmon-containers).
The UI experience of Azure Monitor for containers for Azure AKS-engine Kuberenetes Clusters will be pretty much same as Azure Kubernetes Service(AKS).

For more details, see [Azure Monitor for containers overview](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-overview).

## Troubleshooting

Follow the instructions in [Azure Monitor for Containers Troubleshoot](https://github.com/Microsoft/OMS-docker/tree/aks-engine/Troubleshoot) to troubleshoot the issues related to onboarding of Azure Monitor for containers for AKS-engine Kubernetes cluster(s).

Azure Monitor for containers uses following tags on the master nodes of AKS-engine Kubernetes cluster to detect whether the cluster is AKS-engine or not, onboarded to monitoring or not, determine log analytics workspace id to query the data etc. These tags critical to enable the Azure Monitor for containers experience. 

Following tags are used by Azure Monitor for containers

-------------------------------------------------------------------------------------------------------------------------------------------------------
| Tag Name                        | Tag Value                                                              | Creation Source of the Tag                |
| ----------------------------    | -------------------------------------------------------                | ------------------------------------      | 
| acsengineversion                | v0.24.0                                                                | ACS-engine or AKS-engine                  |
| orchestror                      | Kubernetes                                                             | ACS-engine or AKS-engine                  |
| creationsource                  | acs-engine-k8s-master                                                  | ACS-engine or AKS-engine                  |
| logAnalyticsWorkspaceResourceId | Azure Resource Id of Log Analytics workspace configured on the Agent   | Azure Monitor for containers onboarding   |
| clusterName                     | Resource Id of the cluster Resource group or cluster Name              | Azure Monitor for containers onboarding   |
-------------------------------------------------------------------------------------------------------------------------------------------------------

clusterName is the optional tag. If this tag not specified, clusterName should be Azure Resource Id of the AKS-engine resource group during the install of [azuremonitor-containers](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) chart.
If the clusterName tag specified, please make sure the value of the tag is same used during the install of [azuremonitor-containers](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) chart.

Except logAnalyticsWorkspaceResourceId tag and all other tags are created by ACS-engine (new name is AKS-engine). logAnalyticsWorkspaceResourceId is a custom tag and this tag lost during the upgrade or scale as reported github issue https://github.com/Azure/acs-engine/issues/4155. Azure Monitor for containers should work as long as at least one of the K8s master node has required tags described above. If the Azure Monitor for containers not working, please verify   logAnalyticsWorkspaceResourceId tag after Upgrade or scale up if the Azure Monitor for containers not working.

## Supportability

Supporting of Azure Monitor for containers for AKS-engine (old name is ACS-engine) cluster is best effort basis.
Azure Monitor for container related issues  should be reported to https://github.com/Microsoft/OMS-docker.

Please refer https://github.com/Microsoft/OMS-docker/tree/aks-engine/SUPPORTABILITY.md for more details.

## Let us know!!!
What works? What is missing? What else do you need for this to be useful for you? Let us know at askcoin@microsoft.com.


## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct]
(https://opensource.microsoft.com/codeofconduct/).  For more
information see the [Code of Conduct FAQ]
(https://opensource.microsoft.com/codeofconduct/faq/) or contact
[opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.
