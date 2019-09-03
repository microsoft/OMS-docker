## Overview
The following documentation outlines the steps required to turn on health modeling for a cluster already onboarded to Container Insights Monitoring

* wget https://raw.githubusercontent.com/microsoft/OMS-docker/ci_feature/Kubernetes/container-azm-ms-agentconfig.yaml
* change the agent-settings.health_model enabled setting to true 
* apply the yaml file using kubectl apply -f <updated yaml file path>

#### Viewing the health model
* Navigate to <https://aka.ms/ci-privatepreview>
* There should be a new tab named "Health" in Cluster Insights 
* Note: It might take about 15-20 min after the script runs for the data to show up in the Insights Page of the Cluster


### AKS Engine Onboarding
If your cluster is already onboarded to Monitoring, proceed directly to step 4 and continue from there on. 
1. Add Container Insights Solution to your workspace using the instructions [here](http://aka.ms/coinhelmdoc)
2. Tag your AKS-Engine cluster appropriately using the instructions [here](http://aka.ms/coin-acs-tag-doc)
3. Set the current k8s context to be your AKS Engine cluster (the kube-config should refer to your AKS-Engine cluster)
4. Download the [omsagent-template-aks-engine.yaml](https://github.com/microsoft/OMS-docker/blob/dilipr/kubeHealth/health/omsagent-template-aks-engine.yaml) file to your local machine
5. Update the Values of VALUE_ACS_RESOURCE_NAME, VALUE_WSID {base 64 encoded workspace id} and VALUE_KEY {base 64 encoded workspace key}. See [here](https://github.com/Azure/aks-engine/blob/master/examples/addons/container-monitoring/README.md) on instructions to get the Workspace ID and Key of the file downloaded in Step 4 above
6. Run kubectl delete on the file {kubectl delete -f path_to_file_in_step_4}
7. Run kubectl apply on the file {kubectl apply -f path_to_file_in_step_4}


