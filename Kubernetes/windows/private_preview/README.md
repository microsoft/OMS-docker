# Private Preview - Windows container logging on AKS #

## Prerequisite

Please enable [Azure Monitor for containers](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-onboard) on your AKS clusters.

-----------

## Overview

Azure monitor for containers is already collecting metrics and logs for linux nodes and metrics for windows nodes. This private preview works in conjunction with the aforementioned GA product. It is adding the capability to collect STDOUT and STDERR logs being produced within a container and sending it to the Log Analytics workspace that you've configured in the prerequisite.

-----------

## Steps to onboard

1.	Download the omsagent.yaml file present in this folder manually or use `curl https://raw.githubusercontent.com/microsoft/OMS-docker/kaveesh/windows_private_preview/Kubernetes/windows/private_preview/omsagent.yaml -o omsagent.yaml`
2.	Update AKS_RESOURCE_ID, AKS_REGION with the cluster resource id and region from the properties page in the cluster.
4.	Do a ‘kubectl apply -f omsagent.yaml’ on the cluster you’re trying to onboard.

Once onboarded you should see Daemonset pods running in all of your windows nodes on the AKS cluster in the kube-system namespace.

You can see them running by doing a `kubectl get pods -n kube-system`.

-----------

## Miscellaneous

Values that are going to be replaced in the YAML file:

1.  AKS_RESOURCE_ID: "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.ContainerService/managedClusters/{cluster_name}"
2.  AKS_REGION: "West Europe"

The values for AKS_RESOURCE_ID and AKS_REGION can be found in the Azure portal on the 'properties' page of an AKS cluster.
