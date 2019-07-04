## Overview
The following documentation outlines the steps required to upgrade an existing cluster onboarded to a Log Analytics workspace running the omsagent, to an agent running the workflow that generates health monitor signals into the same workspace.

### Onboarding using a script (AKS)
We have a handy [script](https://github.com/Microsoft/OMS-docker/blob/dilipr/kubeHealth/health/HealthAgentOnboarding.ps1) which can onboard your AKS clusters to a version of the agent that can generate the health model. Read on to find out more

#### Script Prerequisites
* script should run in an elevated command prompt
* kubectl should have been installed and be present in the path

#### What does the script do:
* Installs necessary powershell modules
* Onboards Container Insights solution to the supplied LA workspace if not already onboarded
* Updates the cluster metadata to link the LA workspace ID to the cluster
* Installs the new agent that generates health monitor signals (using kubectl)

#### Script Execution
* Download the script from [here](https://github.com/Microsoft/OMS-docker/blob/dilipr/kubeHealth/health/HealthAgentOnboarding.ps1)
* Run the script:  
 .\HealthAgentOnboarding.ps1 -aksResourceId <AKS_RESOURCE_ID> -aksResourceLocation <AKS_RESOURCE_LOCATION>
 -logAnalyticsWorkspaceResourceId <LOG_ANALYTICS_WS_RESOURCE_ID> (e.g./subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourceGroups/dilipr-health-preview/providers/Microsoft.OperationalInsights/workspaces/dilipr-health-preview)
 * Please make sure the right location of the AKS cluster is passed in to the script (without spaces e.g. eastus, southcentralus)

#### Viewing the health model
* Navigate to <https://aka.ms/ci-privatepreview>
* There should be a new tab named "Health" in Cluster Insights 
* Note: It might take about 15-20 min after the script runs for the data to show up in the Insights Page of the Cluster


### AKS Engine Onboarding
Before proceeding with the onboarding steps, opt out of monitoring using the steps outlined [here]

1. Add Container Insights Solution to your workspace using the instructions [here](http://aka.ms/coinhelmdoc)
2. Tag your AKS-Engine cluster appropriately using the instructions [here](http://aka.ms/coin-acs-tag-doc)
3. Set the current k8s context to be your AKS Engine cluster (the kube-config should refer to your AKS-Engine cluster)
4. Download the [omsagent-template-aks-engine.yaml](https://github.com/microsoft/OMS-docker/blob/dilipr/kubeHealth/health/omsagent-template-aks-engine.yaml) file to your local machine
5. Update the Values of VALUE_ACS_RESOURCE_NAME, VALUE_WSID {base 64 encoded workspace id} and VALUE_KEY {base 64 encoded workspace key}. See [here](https://github.com/Azure/aks-engine/blob/master/examples/addons/container-monitoring/README.md) on instructions to get the Workspace ID and Key of the file downloaded in Step 4 above
6. Run kubectl delete on the file {kubectl delete -f path_to_file_in_step_4}
7. Run kubectl apply on the file {kubectl apply -f path_to_file_in_step_4}


