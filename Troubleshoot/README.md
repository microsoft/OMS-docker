# Troubleshoot Guide for Azure Monitor for containers

# Azure Kubernetes Service (AKS)
The table below summarizes known issues you may face while using Azure Monitor for containers .

| Issues and Error Messages  | Action |
| ---- | --- |
| Error Message `No data for selected filters`  | It may take some time to establish monitoring data flow for newly created clusters. Please allow at least 10-15 minutes for data to appear for your cluster. | 
| Error Message `Error retrieving data` | While Azure Kubenetes Service cluster is setting up for health and performance monitoring, a connection is established between the cluster and Azure Log Analytics workspace. Log Analytics workspace is used to store all monitoring data for your cluster. This error may occurr when your Log Analytics workspace has been deleted or lost. Please check whether your Log Analytics workspace is available. To find your Log Analytics workspace go [here.](https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-manage-access) and your workspace is available. If the workspace is missing, you will need to re-onboard Container Health to your cluster. To re-onboard, you will need to [opt out](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#how-to-stop-monitoring-with-container-health) of monitoring for the cluster and [onboard](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#enable-container-health-monitoring-for-a-new-cluster) again to Container Health. |
| `Error retrieving data` after adding Container Health through az aks cli | When onboarding using az aks cli, very seldom, Container Health may not be properly onboarded. Please check whether the Container Insights Solution is onboarded. To do this, go to your [Log Analytics workspace](https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-manage-access) and see if Container Insights Solution is available by going to the "Solutions" tab under General. To resolve this issue, you will need to redeploy the Container Insights Solution. Please follow the instructions on [how to deploy Azure Monitor - container health solution to your Log Analytics workspace. ](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/docs/solution-onboarding.md) |

# AKS-engine Kubernetes

The table below summarizes known issues you may face while using Azure Monitor for containers .

| Issues and Error Messages  | Action |
| ---- | --- |
| Error Message `No data for selected filters`  | It may take some time to establish monitoring data flow for newly created clusters. Please allow at least 10-15 minutes for data to appear for your cluster. | 
| Error Message `Error retrieving data` | While Aks-Engine cluster is setting up for health and performance monitoring, a connection is established between the cluster and Azure Log Analytics workspace. Log Analytics workspace is used to store all monitoring data for your cluster. This error may occurr when your Log Analytics workspace has been deleted or lost. Please check whether your Log Analytics workspace is available. To find your Log Analytics workspace go [here.](https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-manage-access) and your workspace is available. If the workspace is missing, you will need to re-onboard Container Health to your cluster. To re-onboard, you will need to [onboard] (https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers) again to Container Health. |

# Troubleshooting script

Prequisites: 
- Powershell version 5.1 or above. To install powershell use the following [link](https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6). If you've it installed already, check the powershell version using the command `$psversiontable` and look at the PSVersion row.
- Run powershell as an administrator
- Use 'Get-ExecutionPolicy' to get the current execution policy and store it in a file
- Type the following command 'Set-ExecutionPolicy Unrestricted' before running the script


# Azure Kubernetes Service (AKS)

You can use the troubleshooting script provided [here](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/Troubleshoot/TroubleshootError.ps1) to diagnose the problem.

Steps:
- Download [TroubleshootError.ps1](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/Troubleshoot/TroubleshootError.ps1), [ContainerInsightsSolution.json](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/Troubleshoot/ContainerInsightsSolution.json)
- Collect Subscription ID, Resource group name and AKS Cluster name from the 'Overview' page of your AKS cluster
- Use the following command to run the script : `.\TroubleshootError.ps1 -SubscriptionId <subId> -ResourceGroupName <rgName> -AKSClusterName <aksClusterName>`.
This script will generate a TroubleshootDump.txt which collects detailed information about container health onboarding.
Please send this file to [AskCoin](mailto:askcoin@microsoft.com). We will respond back to you.
- Please remember to 'Set-ExecutionPolicy' to what it was previously(from the value stored in the file) after you've run the script

# Aks-Engine Kubernetes

You can use the troubleshooting script provided [here](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/Troubleshoot/TroubleshootError_AcsEngine.ps1) to diagnose the problem.

Steps:
- Download [TroubleshootError_AcsEngine.ps1](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/Troubleshoot/TroubleshootError_AcsEngine.ps1), [ContainerInsightsSolution.json](https://github.com/Microsoft/OMS-docker/blob/ci_feature_prod/Troubleshoot/ContainerInsightsSolution.json)
- Collect Subscription ID, Resource group name of the Aks-Engine Kubernetes cluster
- Use the following command to run the script : `.\TroubleshootError_AcsEngine.ps1 -SubscriptionId <subId> -ResourceGroupName <rgName>`.
This script will generate a TroubleshootDump.txt which collects detailed information about container health onboarding.
Please send this file to [AskCoin](mailto:askcoin@microsoft.com). We will respond back to you.
- Please remember to 'Set-ExecutionPolicy' to what it was previously(from the value stored in the file) after you've run the script

For more details on Azure Resource Manager template deployment via cli refer to [this documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli). 

If steps above did not help to resolve your issue, you can use either of the following methods to contact us for help:
*	File a [GitHub Issue](https://github.com/Microsoft/OMS-docker/issues)
*	Email [AskCoin](mailto:askcoin@microsoft.com) : Please attach the TroubleshootErrorDump.txt in the email generated by the troubleshooting script if you had tried running the script to solve your problem.
