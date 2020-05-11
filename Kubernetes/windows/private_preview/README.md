## Private Preview - Windows container logging on AKS

Steps to onboard

1.	Download the omsagent.yaml file present in this folder or use `curl https://raw.githubusercontent.com/microsoft/OMS-docker/kaveesh/windows_private_preview/Kubernetes/windows/private_preview/omsagent.yaml`
2.	Update AKS_RESOURCE_ID, AKS_REGION with the cluster resource id and region from the properties page in the cluster.
4.	Do a ‘kubectl apply -f omsagent.yaml’ on the cluster you’re trying to onboard.


E.g. Values that are going to be replaced in the YAML file:

1.  AKS_RESOURCE_ID: "/subscriptions/{subscription_id}/resourcegroups/{resource_group_name}/providers/Microsoft.ContainerService/managedClusters/{cluster_name}"
2.  AKS_REGION: "West Europe"

The values for AKS_RESOURCE_ID and AKS_REGION can be found in the Azure portal on the 'properties' page of an AKS cluster.
