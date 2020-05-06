#!/bin/bash
#
# Execute this directly in Azure Cloud Shell (https://shell.azure.com) by pasting (SHIFT+INS on Windows, CTRL+V on Mac or Linux)
# the following line (beginning with curl...) at the command prompt and then replacing the args:
#  This scripts Onboards AKS cluster to mdm alerts private preview
#      1. Installs Azure Monitor for containers mdm alerts private preview HELM chart to the K8s cluster in Kubeconfig
#      2. Associates cluster with the LA workspace
# Prerequisites :
#     Azure CLI:  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
#     Helm3 : https://helm.sh/docs/intro/install/
#
# bash onboarding_azuremonitor_for_containers.sh <azureSubscriptionId of the cluster> <azureRegionforLogAnalyticsWorkspace> <clusterName> <kubeconfigContextNameOftheCluster>
# For example:
# bash ./onboarding_azuremonitor_for_containers.sh /subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourceGroups/rashmi-mdm-alert/providers/Microsoft.ContainerService/managedClusters/rashmi-mdm-alert /subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourceGroups/rashmi-mdm-alert/providers/Microsoft.OperationalInsights/workspaces/rashmi-mdm-alert rashmi-mdm-alert

if [ $# -le 2 ]
then
  echo "Error: This should be invoked with 3 arguments - clustersubscriptionId, workspaceSubscriptionId, clusterResourceId, clusterRegion, workspaceResourceId and kubeContext name"
  exit 1
fi

echo "clusterResourceId:"${1}
echo "workspaceResourceId:" ${2}
echo "kubeconfig context:"${3}

clusterResourceId=${1}
workspaceResourceId=${2}
kubeconfig=${3}

clusterSubscriptionId="$(cut -d'/' -f3 <<<$clusterResourceId)"
clusterResourceGroup="$(cut -d'/' -f5 <<<$clusterResourceId)"
clusterName="$(cut -d'/' -f9 <<<$clusterResourceId)"
workspaceSubscriptionId="$(cut -d'/' -f3 <<<$workspaceResourceId)"


echo "Set AzureCloud as active cloud for az cli"
az cloud set -n AzureCloud

echo "login to the azure interactively"
az login

echo "setting the subscription id of the cluster: ${clusterSubscriptionId}"
az account set -s ${clusterSubscriptionId}

echo "getting cluster region"
export clusterRegion=$(az resource show --ids $clusterResourceId --query location)
clusterRegion=$(echo $clusterName | tr -d '"')
echo $clusterRegion


# echo "getting cluster resource group"
# export clusterResourceGroup=$(az resource show --ids $clusterResourceId --query resourceGroup)
# clusterResourceGroup=$(echo $clusterResourceGroup | tr -d '"')
# echo $clusterResourceGroup

# echo "getting cluster name"
# export clusterName=$(az resource show --ids $clusterResourceId --query name)
# clusterName=$(echo $clusterName | tr -d '"')
# echo $clusterName

echo "Disabling monitoring on the cluster"
#az aks disable-addons -a monitoring -g $clusterResourceGroup -n $clusterName

echo "setting the subscription id of the workspace: ${workspaceSubscriptionId}"
az account set -s ${workspaceSubscriptionId}

echo "getting workspace Guid"
export workspaceGuid=$(az resource show --ids $workspaceResourceId --resource-type Microsoft.OperationalInsights/workspaces --query properties.customerId)
workspaceGuid=$(echo $workspaceGuid | tr -d '"')
echo $workspaceGuid

echo "getting workspace primaryshared key"
workspaceKey=$(az rest --method post --uri $workspaceResourceId/sharedKeys?api-version=2015-11-01-preview --query primarySharedKey)
workspaceKey=$(echo $workspaceKey | tr -d '"')
echo $workspaceKey

echo "installing Azure Monitor for containers HELM chart for MDM alerts preview..."

echo "adding azmon-preview repo"
# helm repo add ci-mdm-alert https://rashmichandrashekar.github.io/azure-monitor-containers-helm-chart-private/
helm repo add azmon-preview-mdm-alert https://rashmichandrashekar.github.io/azuremonitor-containers-charts/
echo "updating helm repo to get latest charts"
helm repo update

# helm upgrade azmon-containers-ci-mdm-alert ci-mdm-alert/azuremonitor-containers --install --set omsagent.secret.wsid=$workspaceGuid,omsagent.secret.key=$workspaceKey,omsagent.env.clusterId=${3},omsagent.env.clusterRegion=${4} --kube-context ${6}
helm upgrade --install azmon-containers-ci-mdm-alert-release --set omsagent.secret.wsid=$workspaceGuid,omsagent.secret.key=$workspaceKey,omsagent.env.clusterId=${3},omsagent.env.clusterRegion=${4} azmon-preview-mdm-alert/azuremonitor-containers --kube-context ${6}
echo "chart installation completed."

echo "setting the subscription id of the cluster: ${clusterSubscriptionId}"
az account set -s ${clusterSubscriptionId}

echo "getting cluster object"
clusterGetResponse=$(az rest --method get --uri $clusterResourceId?api-version=2019-11-01)

echo $clusterGetResponse | jq '.properties.addonProfiles.omsagent.config.logAnalyticsWorkspaceResourceID=$workspaceResourceId'

export jqquery=".properties.addonProfiles.omsagent.config.logAnalyticsWorkspaceResourceID=$workspaceResourceId"
echo $clusterGetResponse | jq $jqquery > putrequestbody.json

az rest --method put --uri $clusterResourceId?api-version=2019-11-01 --body @putrequestbody.json --headers Content-Type=application/json