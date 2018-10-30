#!/bin/bash

# login
az login

# set subscription of the acs-engine resource group
az account set -s <subscriptionId>

# check the log analytics workspace resource exists or not
az resource show --ids "/subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourceGroups/gangams-acsengine-ws-rg/providers/Microsoft.OperationalInsights/workspaces/gangams-acsengine-workspace"

# get the all existing k8s master nodes
resources=$(az resource list -g <resource group name of acs engine cluster> --resource-type "Microsoft.Compute/virtualMachines" --query "[?starts_with(name,'k8s-master')].id" --output tsv)

# attach logAnalyticsWorkspaceResourceId=<resourceId of the log analytics workspace> to all K8s master nodes 
for resid in $resources
 do
    jsonrtag=$(az resource show --id $resid --query tags)
    rt=$(echo $jsonrtag | tr -d '"{},' | sed 's/: /=/g')
    az resource tag --tags $rt logAnalyticsWorkspaceResourceId=<resourceId of the log analytics workspace> --id $resid
done



