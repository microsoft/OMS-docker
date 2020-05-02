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
# bash ./onboarding_azuremonitor_for_containers.sh 00000000-0000-0000-0000-000000000000 eastus myocp42 admin

if [ $# -le 5 ]
then
  echo "Error: This should be invoked with 6 arguments, clustersubscriptionId, workspaceSubscriptionId, clusterResourceId, clusterRegion, workspaceResourceId and kubeContext name"
  exit 1
fi

echo "clusterSubscriptionId:"${1}
echo "workspaceSubscriptionId:"${2}
echo "clusterResourceId:"${3}
echo "clusterRegion:"${4}
echo "workspaceResourceId:" ${5}
echo "kubeconfig context:"${6}

clusterSubscriptionId=${1}
workspaceSubscriptionId=${2}
clusterResourceId=${3}
clusterRegion=${4}
workspaceResourceId=${5}
kubeconfig=${6}


echo "Set AzureCloud as active cloud for az cli"
az cloud set -n AzureCloud

echo "login to the azure interactively"
az login

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
helm repo add azmon-preview https://ganga1980.github.io/azuremonitor-containers-helm-charts/
echo "updating helm repo to get latest charts"
helm repo update

helm upgrade --install azmon-containers-release-1 --set omsagent.secret.wsid=$workspaceGuid,omsagent.secret.key=$workspaceKey,omsagent.env.clusterName=${3} azmon-preview/azuremonitor-containers --kube-context ${4}
echo "chart installation completed."