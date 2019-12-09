#!/bin/bash
#
# Execute this directly in Azure Cloud Shell (https://shell.azure.com) by pasting (SHIFT+INS on Windows, CTRL+V on Mac or Linux)
# the following line (beginning with curl...) at the command prompt and then replacing the args:
#  This scripts Onboards Azure Monitor for containers to Kubernetes cluster hosted outside and connected to Azure via Azure Arc cluster
#
#      1. Creates the Default Azure log analytics workspace if doesn't exist one in specified subscription
#      2. Adds the ContainerInsights solution to the Azure log analytics workspace
#      3. Adds the logAnalyticsWorkspaceResourceId tag on the provided Azure Arc Cluster
#      4. Installs Azure Monitor for containers HELM chart to the K8s cluster in Kubeconfig
# Prerequisites :
#     Azure CLI:  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
#     Helm3 : https://helm.sh/docs/intro/install/
#
# bash <script> <azureArcResourceId> <kube-context>
# For example:
# bash onboarding_azuremonitor_for_containers.sh /subscriptions/57ac26cf-a9f0-4908-b300-9a4e9a0fb205/resourceGroups/AzureArcTest/providers/Microsoft.Kubernetes/connectedClusters/AzureArcTest1 MyK8sTestCluster

if [ $# -le 1 ]
then
  echo "Error: This should be invoked with 2 arguments, clusterResourceId and kubeContext name"
  exit 1
fi

echo "clusterResourceId:"${1}
echo "kubeconfig context:"${2}

subscriptionId="$(echo ${1} | cut -d'/' -f3)"
resourceGroup="$(echo ${1} | cut -d'/' -f5)"
providerName="$(echo ${1} | cut -d'/' -f7)"
clusterName="$(echo ${1} | cut -d'/' -f9)"

echo "cluster SubscriptionId:" $subscriptionId
echo "cluster ResourceGroup:" $resourceGroup
echo "cluster ProviderName:" $providerName
echo "cluster Name:" $clusterName

echo "Set AzureCloud as active cloud for az cli"
az cloud set -n AzureCloud

echo "login to the azure interactively"
az login

echo "set the arc cluster subscription id: ${subscriptionId}"
az account set -s ${subscriptionId}

export clusterRegion=$(az resource show --ids ${1} --query location)
echo "cluster region:" $clusterRegion

# mapping fors for default Azure Log Analytics workspace
declare -A AzureCloudLocationToOmsRegionCodeMap=(
[australiasoutheast]=ASE
[australiaeast]=EAU
[australiacentral]=CAU
[canadacentral]=CCA
[centralindia]=CIN
[centralus]=CUS
[eastasia]=EA
[eastus]=EUS
[eastus2]=EUS2
[eastus2euap]=EAP
[francecentral]=PAR
[japaneast]=EJP
[koreacentral]=SE
[northeurope]=NEU
[southcentralus]=SCUS
[southeastasia]=SEA
[uksouth]=SUK
[usgovvirginia]=USGV
[westcentralus]=EUS
[westeurope]=WEU
[westus]=WUS
[westus2]=WUS2
)

declare -A AzureCloudRegionToOmsRegionMap=(
[australiacentral]=australiacentral
[australiacentral2]=australiacentral
[australiaeast]=australiaeast
[australiasoutheast]=australiasoutheast
[brazilsouth]=southcentralus
[canadacentral]=canadacentral
[canadaeast]=canadacentral
[centralus]=centralus
[centralindia]=centralindia
[eastasia]=eastasia
[eastus]=eastus
[eastus2]=eastus2
[francecentral]=francecentral
[francesouth]=francecentral
[japaneast]=japaneast
[japanwest]=japaneast
[koreacentral]=koreacentral
[koreasouth]=koreacentral
[northcentralus]=eastus
[northeurope]=northeurope
[southafricanorth]=westeurope
[southafricawest]=westeurope
[southcentralus]=southcentralus
[southeastasia]=southeastasia
[southindia]=centralindia
[uksouth]=uksouth
[ukwest]=uksouth
[westcentralus]=eastus
[westeurope]=westeurope
[westindia]=centralindia
[westus]=westus
[westus2]=westus2
)

export workspaceRegionCode="EUS"
export workspaceRegion="eastus"

if [ -n "${AzureCloudRegionToOmsRegionMap[$clusterRegion]}" ];
then
   workspaceRegion=${AzureCloudRegionToOmsRegionMap[$clusterRegion]}
fi
echo "Workspace Region:"$workspaceRegion

if [ -n "${AzureCloudLocationToOmsRegionCodeMap[$workspaceRegion]}" ];
then
   workspaceRegionCode=${AzureCloudLocationToOmsRegionCodeMap[$workspaceRegion]}
fi
echo "Workspace Region Code:"$workspaceRegionCode

export defaultWorkspaceResourceGroup="DefaultResourceGroup-"$workspaceRegionCode
export isRGExists=$(az group exists -g $defaultWorkspaceResourceGroup)
export defaultWorkspaceName="DefaultWorkspace-"$subscriptionId"-"$workspaceRegionCode

if $isRGExists
then echo "using existing default resource group:"$defaultWorkspaceResourceGroup
else
  az group create -g $defaultWorkspaceResourceGroup -l $workspaceRegion
fi

export workspaceList=$(az resource list -g $defaultWorkspaceResourceGroup -n $defaultWorkspaceName  --resource-type Microsoft.OperationalInsights/workspaces)
if [ $workspaceList = "[]" ];
then
# create new default workspace since no mapped existing default workspace
echo '{"location":"'"$workspaceRegion"'", "properties":{"sku":{"name": "standalone"}}}' > WorkspaceProps.json
cat WorkspaceProps.json
workspace=$(az resource create -g $defaultWorkspaceResourceGroup -n $defaultWorkspaceName --resource-type Microsoft.OperationalInsights/workspaces --is-full-object -p @WorkspaceProps.json)
else echo "using existing default workspace:"$defaultWorkspaceName
fi

workspaceResourceId=$(az resource show -g $defaultWorkspaceResourceGroup -n $defaultWorkspaceName  --resource-type Microsoft.OperationalInsights/workspaces --query id)
workspaceResourceId=$(echo $workspaceResourceId | tr -d '"')

# get the workspace guid
export workspaceGuid=$(az resource show -g $defaultWorkspaceResourceGroup -n $defaultWorkspaceName  --resource-type Microsoft.OperationalInsights/workspaces --query properties.customerId)
workspaceGuid=$(echo $workspaceGuid | tr -d '"')

echo "workspaceResourceId:"$workspaceResourceId
echo "workspaceGuid:"$workspaceGuid

echo "adding containerinsights solution to workspace"
solution=$(az group deployment create -g $defaultWorkspaceResourceGroup --template-uri https://raw.githubusercontent.com/microsoft/OMS-docker/ci_feature_prod/docs/templates/azuremonitor-containerSolution.json --parameters workspaceResourceId=$workspaceResourceId --parameters workspaceRegion=$workspaceRegion)

echo "getting workspace primaryshared key"
workspaceKey=$(az rest --method post --uri $workspaceResourceId/sharedKeys?api-version=2015-11-01-preview --query primarySharedKey)
workspaceKey=$(echo $workspaceKey | tr -d '"')
echo $workspaceKey

echo "attach loganalyticsworkspaceResourceId tag on to cluster resource"
status=$(az resource tag --tags logAnalyticsWorkspaceResourceId=$workspaceResourceId -g $resourceGroup -n $clusterName --resource-type Microsoft.Kubernetes/connectedClusters)

echo "installing Azure Monitor for containers HELM chart ..."

echo "adding helm incubator repo"
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
echo "updating helm repo to get latest charts"
helm repo update

helm install azmon-containers-release-1 --set omsagent.secret.wsid=$workspaceGuid,omsagent.secret.key=$workspaceKey,omsagent.env.clusterId=${1} incubator/azuremonitor-containers --kube-context ${2}
echo "chart installation completed."

echo "Proceed to https://aka.ms/azmon-containers-azurearc to view health of your newly onboarded Azure Arc cluster"
