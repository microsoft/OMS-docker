#!/bin/bash
#
# Execute this directly in Azure Cloud Shell (https://shell.azure.com) by pasting (SHIFT+INS on Windows, CTRL+V on Mac or Linux)
# the following line (beginning with curl...) at the command prompt and then replacing the args:
# This script adds the Monitoring Metrics Publisher role assignment to specified AKS cluster
# Note: owner or admin permission required on the subscription to add the role assignment
# Prerequisites :
#     Azure CLI:  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
# curl -sL https://git.io/aks-mdm-onboarding | bash -s <subscriptionId> <clusterResourceGroup> <clusterName> 
#
#   [Required]  ${1}  <subscriptionId>    subscriptionId  of the AKS cluster 
#   [Required]  ${2}  <clusterResourceGroup>      resource group of the AKS cluster
#   [Required]  ${3}  <clusterName>           name of the AKS cluster
#
# For example:
#
# curl -sL https://git.io/aks-mdm-onboarding | bash -s "00000000-0000-0000-0000-000000000000" "MyAKSClusterRG" "MyAKSCluster"
#

echo "subscriptionId"= ${1}
echo "clusterResourceGroup" = ${2}
echo "clusterName" = ${3}

# login to azure 
az  login

# set the account with specified subscriptionId
az account set -s ${1}

# get the cluster resource id

export CLUSTER_RESOURCE_ID=$(az aks show -g ${2} -n ${3} --query id -o tsv)
echo "clusterResourceId" = $CLUSTER_RESOURCE_ID

# get the clientId of cluster service principal
export SP_ID=$(az aks show -g  ${2} -n ${3} --query servicePrincipalProfile.clientId -o tsv)
echo "ClusterServicePrincipalClientId" = $SP_ID

echo " - Running .."

#  assign the cluster spn with Monitoring Metrics Publisher role to the cluster resource
az role assignment create --assignee $SP_ID --scope $CLUSTER_RESOURCE_ID --role "Monitoring Metrics Publisher"

# completed the role assignment
echo "completed the role assignment"
