#!/bin/bash
#
# Execute this directly in Azure Cloud Shell (https://shell.azure.com) by pasting (SHIFT+INS on Windows, CTRL+V on Mac or Linux)
# the following line (beginning with curl...) at the command prompt and then replacing the args:
#  This script adds the 'Monitoring Metrics Publisher' role assignment for all the AKS clusters 
#  in specified subscription
#  Note: 'Microsoft.Authorization/roleAssignments/write'  permission required on the  each cluster resource to add the role assignment.
#  Of the built-in roles, only Owner and User Access Administrator are granted access to this permission.
# Prerequisites :
#     Azure CLI:  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
#           jq : sudo apt-get install jq
#  curl -sL https://git.io/aks-mdm-onboarding-atscale | bash -s <subscriptionId>
#
#  [Required]  ${1}  <subscriptionId>    subscriptionId  of the AKS cluster 
#
#  For example:
#
#  curl -sL https://git.io/az-aks-mdm-onboarding | bash -s "00000000-0000-0000-0000-000000000000"
#

echo "subscriptionId"= ${1}

# login to azure interactively 
az login

# set the account with specified subscriptionId
az account set -s ${1}

# get all the aks clusters in specified subscription
export CLUSTERS_LIST=$(az aks list  --query '[].{clusterId:id, name:name, rg:resourceGroup}' -o json)

for cluster in $(echo $CLUSTERS_LIST | jq -c '.[]'); do
      
    export clusterRG=$(echo $cluster | jq -r  '.rg')
    export clusterName=$(echo $cluster | jq -r  '.name')
    export clusterId=$(echo $cluster | jq -r  '.clusterId')

    # get the client id of the cluster service principal
    export SP_ID=$(az aks show -g $clusterRG -n $clusterName --query servicePrincipalProfile.clientId -o tsv)
       
    # add the service principal with Monitoring Metrics Publisher role assignment
    echo "adding service principal for aks cluster $clusterName"
    az role assignment create --assignee $SP_ID --scope $clusterId --role "Monitoring Metrics Publisher"
    echo "role assignment completed for aks cluster $clusterName"       
done

echo "completed role assignments for all AKS clusters in subscription: ${1}"
