# Trying the Azure Monitor for containers for AKS-engine Cluster(s)

Azure Monitor for containers is a feature designed to monitor the performance of container workloads deployed to [AKS-engine](https://github.com/Azure/aks-engine) (formerly known as ACS-engine) cluster(s) hosted on Azure. Monitoring your containers is critical, especially when you're running a production cluster, at scale, with multiple applications.

Azure Monitor for containers gives you performance visibility by collecting memory and processor metrics from controllers, nodes, and containers that are available in Kubernetes through the Metrics API. Container logs are also collected. After you enable monitoring from Kubernetes clusters, these metrics and logs are automatically collected for you through a containerized version of the Log Analytics agent for Linux and stored in your Log Analytics workspace.

This site will provide you the instructions on how to onboard to Azure Monitor for containers for AKS-engine cluster. 

For more details on how to use the product, see [Azure Monitor for containers](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-analyze)

### Supported Kubernetes versions, Container Runtime(s) and OS Distro(s):
Below support matrix are based on [AKS-engine cluster definition](https://github.com/Azure/acs-engine/blob/master/docs/clusterdefinition.md): 
- Kubernetes versions, same as [AKS supported versions](https://docs.microsoft.com/en-us/azure/aks/supported-kubernetes-versions)
- Container Runtime : Docker, Moby
- Linux Distros for master and agent pool of AKS-engine: ubuntu, AKS, and aks-docker-engine
- RBAC and Non-RBAC

## How to Set up
1. You will need a location to store your monitoring data. If you do not have an Azure Log Analytics Workspace, please create it [here](https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-quick-create-workspace).
2. You will need to add the "Container Insights" solution to your workspace if you do not have any. Please follow the steps [here](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/docs/solution-onboarding.md).
3. You will need to deploy the agent using helm. Please follow the steps [here](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers).
4. Finally, please run this [script](https://github.com/Microsoft/OMS-docker/blob/ci_feature/docs/attach-monitoring-tags.md) which helps you set the tags to the AKS-engine. 

### Agent Upgrade
You can upgrade the agent to a newer version by re-deploying the [agent.](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) 

## What now?
Once you're set up, you can go to the [Azure portal](https://portal.azure.com) and go to Azure Monitor and click on the "Containers" on the left TOC. There, you will see a list of onboarded AKS-engine clusters. 

For more details on how to use the product, go to [Azure Monitor for containers overview](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-overview).

## Troubleshooting
Follow the instructions in [Azure Monitor for Containers Troubleshoot](https://github.com/Microsoft/OMS-docker/tree/aks-engine/Troubleshoot) to troubleshoot the issues related to onboarding of Azure Monitor for containers for AKS-engine Kubernetes cluster(s).

Azure Monitor for containers uses the following tags on the master nodes of AKS-engine Kubernetes cluster to detect whether the cluster is AKS-engine or not, onboarded to monitoring or not, determine log analytics workspace id to query the data etc. These tags critical to enable the Azure Monitor for containers experience. 

Following Azure tags are used by Azure Monitor for containers:

-------------------------------------------------------------------------------------------------------------------------------------------------------
| Tag Name                             | Tag Value                                                              | Creation Source of the Tag                    |
| -----------------------------------  | ------------------------------------------------------           | ------------------------------------                | 
| acsengineversion or aksengineversion | v0.24.0 or higher                                                | ACS-engine for acsengineversion tag else AKS-engine |
| orchestrator                         | Kubernetes                                                       | ACS-engine or AKS-engine                            |
| creationsource                       | acs-engine-k8s-master-* or aks-engine-k8s-master                 | ACS-engine for the tag which starts with acs-engine-k8s-master else  AKS-engine                            |
| logAnalyticsWorkspaceResourceId      | Azure Resource Id of Log Analytics workspace configured on the Agent | Azure Monitor for containers onboarding         |
| clusterName                          | Resource Id of the cluster Resource group or cluster Name        | Azure Monitor for containers onboarding             |
------------------------------------------------------------------------------------------------------------------------------------------------------------

Note: clusterName is the optional tag. If this tag not specified, clusterName should be Azure Resource Id of the AKS-engine resource group during the install of [azuremonitor-containers](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) chart.
If the clusterName tag specified, please make sure the value of the tag is same used during the install of [azuremonitor-containers](https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) chart.

Except logAnalyticsWorkspaceResourceId tag and all other tags are created by ACS-engine (new name is AKS-engine). logAnalyticsWorkspaceResourceId is a custom tag and this tag lost during the upgrade or scale as reported github issue https://github.com/Azure/acs-engine/issues/4155. Azure Monitor for containers should work as long as at least one of the K8s master node has required tags described above. If the Azure Monitor for containers not working, please verify   logAnalyticsWorkspaceResourceId tag after Upgrade or scale up if the Azure Monitor for containers not working.

## Supportability
Supporting of Azure Monitor for containers for AKS-engine (formerly known as ACS-engine) cluster is best effort basis.
Azure Monitor for container for related issues should be reported to [github issues.](https://github.com/Microsoft/OMS-docker/issues) 

## Let us know!!!
What works? What is missing? What else do you need for this to be useful for you? Let us know at askcoin@microsoft.com.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct]
(https://opensource.microsoft.com/codeofconduct/).  For more
information see the [Code of Conduct FAQ]
(https://opensource.microsoft.com/codeofconduct/faq/) or contact
[opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.
