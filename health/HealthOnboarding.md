## Overview
The following documentation outlines the steps required to upgrade an existing cluster onboarded to a Log Analytics workspace running the omsagent, to an agent running the workflow that generates health monitor signals into the same workspace.

### Onboarding using a script (AKS)
We have a handy [script](https://github.com/Microsoft/OMS-docker/blob/dilipr/kubeHealth/health/HealthAgentOnboarding.ps1) which can onboard your AKS clusters to a version of the agent that can generate the health model. Read on to find out more

#### Script Prerequisites
* script should run in an elevated command prompt
* kubectl should have been installed and be present in the path

#### What does the script do:
* Do a custom off-boarding of the cluster from Monitoring 
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

#### Notes
* After running the script, if there is more than one version of the omsagent DaemonSet running on a node (you can figure this out by running __kubecetl get pods -n kube-system -o wide__), [disable monitoring](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-optout) and re-run the onboarding script

#### Viewing the health model
* Navigate to <https://aka.ms/clusterhealthpreview>
* There should be a new tab named "Health" in Cluster Insights 
* Note: It might take about 15-20 min after the script runs for the data to show up in the Insights Page of the Cluster


### AKS Engine Onboarding
1. Add Container Insights Solution to your workspace using the instructions [here](http://aka.ms/coinhelmdoc)
2. Tag your AKS-Engine cluster appropriately using the instructions [here](http://aka.ms/coin-acs-tag-doc)
3. Set the current k8s context to be your AKS Engine cluster (the kube-config should refer to your AKS-Engine cluster)
4. Download the [omsagent-template-aks-engine.yaml](https://github.com/microsoft/OMS-docker/blob/dilipr/kubeHealth/health/omsagent-template-aks-engine.yaml) file to your local machine
5. Update the Values of VALUE_ACS_RESOURCE_NAME, VALUE_WSID {base 64 encoded workspace id} and VALUE_KEY {base 64 encoded workspace key}. See [here](https://github.com/Azure/aks-engine/blob/master/examples/addons/container-monitoring/README.md) on instructions to get the Workspace ID and Key of the file downloaded in Step 5 above
6. Run kubectl apply on the file {kubectl apply -f path_to_file_in_step_4}


## Manual Steps (AKS cluster)

#### Prerequisites
* Cluster that has already been onboarded to Monitoring using a Log Analytics workspace
* kubectl should be intalled and should be available in the path
* Powershell with the following modules installed (Else the onboarding script will install those for you)
  * Az.Accounts
  * Az.Resources
  * Az.OperationalInsights
  * Az.Aks
* Run in an elevated powershell window

#### Steps
1. Copy and paste the following JSON into a file. 

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "aksResourceId": {
       "type": "string",
       "metadata": {
         "description": "AKS Cluster Resource ID"
       }
   },
  "aksResourceLocation": {
    "type": "string",
    "metadata": {
       "description": "Location of the AKS resource e.g. \"East US\""
     }
   }
},
"resources": [
  {
    "name": "[split(parameters('aksResourceId'),'/')[8]]",
    "type": "Microsoft.ContainerService/managedClusters",
    "location": "[parameters('aksResourceLocation')]",
    "apiVersion": "2018-03-31",
    "properties": {
      "mode": "Incremental",
      "id": "[parameters('aksResourceId')]",
      "addonProfiles": {
        "omsagent": {
          "enabled": false,
          "config": {
              "loganalyticsworkspaceresourceid": "[parameters('workspaceResourceId')]"
          }
        }
       }
     }
   }
  ]
}
```

2. Save this file as HealthPreviewOnboarding.json in your local folder

3. Copy and paste the following JSON into a file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
 	 "aksResourceId": {
 	   "value": "VALUE_AKS_RESOURCE_ID"
    },
    "aksResourceLocation": {
 	 "value": "eastus"
    },
    "workspaceResourceId": {
 	 "value": "VALUE_WORKSPACE_RESOURCE_ID"
    }  
  }
}
```

4. Save this file as HealthPreviewOnboardingParams.json in your local folder

5. Replace the contents of the VALUE_AKS_RESOURCE_ID and VALUE_WORKSPACE_RESOURCE_ID with the correct values in the HealthPreviewOnboardingParams file
The VALUE_AKS_RESOURCE_ID (resource id of the cluster) can be found in the Properties section of the AKS cluster. VALUE_WORKSPACE_RESOURCE_ID (get the value of this from the portal when the cluster is onboarded) is of the format  /subscriptions/<subscriptionId>/resourceGroups/<resourceGroupName>/providers/Microsoft.OperationalInsights/workspaces/<workspaceName> -- replace the subscriptionId, resourceGroupName and workspaceName values with the right ones.

6. Run the following commands from a powershell window
* Connect-AzAccount  
* Select-AzSubscription -SubscriptionName <yourSubscriptionName>  
* New-AzResourceGroupDeployment -Name opt-out -ResourceGroupName <ResourceGroupName> -TemplateFile .\HealthPreviewOnboarding.json -TemplateParameterFile .\HealthPreviewOnboardingParams.json  

7. Copy the following content into a yaml file: (You will use this file to do a kubectl apply on the kubernetes cluster). This file is also available [here](https://raw.githubusercontent.com/microsoft/OMS-docker/dilipr/kubeHealth/health/omsagent-template.yaml)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: omsagent
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: omsagent-reader
rules:
- apiGroups: [""]
  resources: ["pods", "events", "nodes", "namespaces", "services"]
  verbs: ["list", "get", "watch"]
- apiGroups: ["extensions"]
  resources: ["deployments"]
  verbs: ["list"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: omsagentclusterrolebinding
subjects:
  - kind: ServiceAccount
    name: omsagent
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: omsagent-reader
  apiGroup: rbac.authorization.k8s.io
---
kind: ConfigMap
apiVersion: v1
data:
  kube.conf: |- 
     # Fluentd config file for OMS Docker - cluster components (kubeAPI)
     #fluent forward plugin
     <source>
      type forward
      port 25235
      bind 0.0.0.0
     </source>

     #Kubernetes pod inventory
     <source>
      type kubepodinventory
      tag oms.containerinsights.KubePodInventory
      run_interval 60s
      log_level debug
     </source>

     #Kubernetes events
     <source>
      type kubeevents
      tag oms.containerinsights.KubeEvents
      run_interval 60s
      log_level debug
      </source>

     #Kubernetes logs
     <source>
      type kubelogs
      tag oms.api.KubeLogs
      run_interval 60s
     </source>

     #Kubernetes services
     <source>
      type kubeservices
      tag oms.containerinsights.KubeServices
      run_interval 60s
      log_level debug
     </source>

     #Kubernetes Nodes
     <source>
      type kubenodeinventory
      tag oms.containerinsights.KubeNodeInventory
      run_interval 60s
      log_level debug
     </source>

     #Kubernetes perf
     <source>
      type kubeperf
      tag oms.api.KubePerf
      run_interval 60s
      log_level debug
     </source>

     #Kubernetes health
     <source>
      type kubehealth
      tag oms.api.KubeHealth.ReplicaSet
      run_interval 60s
      log_level debug
     </source>
     
     #cadvisor perf- Windows nodes
     <source>
      type wincadvisorperf
      tag oms.api.wincadvisorperf
      run_interval 60s
      log_level debug
     </source>

     <filter mdm.kubepodinventory** mdm.kubenodeinventory**>
      type filter_inventory2mdm
      custom_metrics_azure_regions eastus,southcentralus,westcentralus,westus2,southeastasia,northeurope,westEurope
      log_level info
     </filter>

     # custom_metrics_mdm filter plugin for perf data from windows nodes
     <filter mdm.cadvisorperf**>
      type filter_cadvisor2mdm
      custom_metrics_azure_regions eastus,southcentralus,westcentralus,westus2,southeastasia,northeurope,westEurope
      metrics_to_collect cpuUsageNanoCores,memoryWorkingSetBytes
      log_level info
     </filter>

     #health model aggregation filter
     <filter oms.api.KubeHealth**>
      type filter_health_model_builder
     </filter>

     <match oms.containerinsights.KubePodInventory**>
      type out_oms
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_kubepods*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
     </match>

     <match oms.containerinsights.KubeEvents**>
      type out_oms
      log_level debug
      num_threads 5
      buffer_chunk_limit 5m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_kubeevents*.buffer
      buffer_queue_limit 10
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
     </match>

     <match oms.api.KubeLogs**>
      type out_oms_api
      log_level debug
      buffer_chunk_limit 10m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_api_kubernetes_logs*.buffer
      buffer_queue_limit 10
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
     </match>

     <match oms.containerinsights.KubeServices**>
      type out_oms
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_kubeservices*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
     </match>

     <match oms.containerinsights.KubeNodeInventory**>
      type out_oms
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/state/out_oms_kubenodes*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
     </match>

     <match oms.containerinsights.ContainerNodeInventory**>
      type out_oms
      log_level debug
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_containernodeinventory*.buffer
      buffer_queue_limit 20
      flush_interval 20s
      retry_limit 10
      retry_wait 15s
      max_retry_wait 9m
     </match>

     <match oms.api.KubePerf**>	
      type out_oms
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_kubeperf*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
     </match>

     <match mdm.kubepodinventory** mdm.kubenodeinventory** >
      type out_mdm
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_mdm_*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
      retry_mdm_post_wait_minutes 60
     </match>

     <match oms.api.wincadvisorperf**>
      type out_oms
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_api_wincadvisorperf*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
     </match>

     <match mdm.cadvisorperf**>
      type out_mdm
      log_level debug
      num_threads 5
      buffer_chunk_limit 20m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_mdm_cdvisorperf*.buffer
      buffer_queue_limit 20
      buffer_queue_full_action drop_oldest_chunk
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
      max_retry_wait 9m
      retry_mdm_post_wait_minutes 60
     </match>
     
     <match oms.api.KubeHealth.AgentCollectionTime**>
      type out_oms_api
      log_level debug
      buffer_chunk_limit 10m
      buffer_type file
      buffer_path %STATE_DIR_WS%/out_oms_api_kubehealth*.buffer
      buffer_queue_limit 10
      flush_interval 20s
      retry_limit 10
      retry_wait 30s
     </match>
metadata:
  name: omsagent-rs-config
  namespace: kube-system
---
apiVersion: v1
kind: Secret
metadata:
 name: omsagent-secret
 namespace: kube-system
type: Opaque
data:
  #BASE64 ENCODED (Both WSID & KEY) INSIDE DOUBLE QUOTE ("")
  WSID: "VALUE_WSID"
  KEY: "VALUE_KEY"
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
 name: omsagent
 namespace: kube-system
spec:
 updateStrategy:
  type: RollingUpdate
 template:
  metadata:
   labels:
    dsName: "omsagent-ds"
   annotations:
    agentVersion: "1.10.0.1"
    dockerProviderVersion: "5.0.0-0"
    schema-versions: "v1"
  spec:
   serviceAccountName: omsagent
   containers:
     - name: omsagent 
       image: "mcr.microsoft.com/azuremonitor/containerinsights/ciprod:healthpreview06272019"
       imagePullPolicy: IfNotPresent
       resources:
        limits:
         cpu: 150m
         memory: 300Mi
        requests:
         cpu: 75m
         memory: 225Mi
       env:
       - name: AKS_RESOURCE_ID
         value: "VALUE_AKS_RESOURCE_ID_VALUE"
       - name: AKS_REGION
         value: "VALUE_AKS_REGION_VALUE"
       #Uncomment below two lines for ACS clusters and set the cluster names manually. Also comment out the above two lines for ACS clusters
       #- name: ACS_RESOURCE_NAME
         #value: "my_acs_cluster_name"
       - name: CONTROLLER_TYPE
         value: "DaemonSet"
       - name: NODE_IP
         valueFrom:
            fieldRef:
              fieldPath: status.hostIP  
       securityContext:
         privileged: true
       ports:
       - containerPort: 25225
         protocol: TCP 
       - containerPort: 25224
         protocol: UDP
       volumeMounts:
        - mountPath: /hostfs
          name: host-root
          readOnly: true
        - mountPath: /var/run/host
          name: docker-sock
        - mountPath: /var/log 
          name: host-log
        - mountPath: /var/lib/docker/containers 
          name: containerlog-path
        - mountPath: /etc/kubernetes/host
          name: azure-json-path
        - mountPath: /etc/omsagent-secret
          name: omsagent-secret
        - mountPath: /etc/config/settings
          name: settings-vol-config
          readOnly: true
       livenessProbe:
        exec:
         command:
         - /bin/bash
         - -c
         - /opt/livenessprobe.sh
        initialDelaySeconds: 60
        periodSeconds: 60
   nodeSelector:
    beta.kubernetes.io/os: linux    
   # Tolerate a NoSchedule taint on master that ACS Engine sets.
   tolerations:
    - key: "node-role.kubernetes.io/master"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"     
   volumes:
    - name: host-root
      hostPath:
       path: /
    - name: docker-sock 
      hostPath:
       path: /var/run
    - name: container-hostname
      hostPath:
       path: /etc/hostname
    - name: host-log
      hostPath:
       path: /var/log
    - name: containerlog-path
      hostPath:
       path: /var/lib/docker/containers
    - name: azure-json-path
      hostPath:
       path: /etc/kubernetes
    - name: omsagent-secret
      secret:
       secretName: omsagent-secret
    - name: settings-vol-config
      configMap:
        name: container-azm-ms-agentconfig
        optional: true
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
 name: omsagent-rs
 namespace: kube-system
spec:
 replicas: 1
 selector:
  matchLabels:
   rsName: "omsagent-rs"
 strategy:
  type: RollingUpdate
 template:
  metadata:
   labels:
    rsName: "omsagent-rs"
   annotations:
    agentVersion: "1.10.0.1"
    dockerProviderVersion: "5.0.0-0"
    schema-versions: "v1"
  spec:
   serviceAccountName: omsagent
   containers:
     - name: omsagent 
       image: "mcr.microsoft.com/azuremonitor/containerinsights/ciprod:healthpreview06272019"
       imagePullPolicy: IfNotPresent
       resources:
        limits:
         cpu: 150m
         memory: 500Mi
        requests:
         cpu: 50m
         memory: 175Mi
       env:
       #- name: AKS_RESOURCE_ID
       #  value: "VALUE_AKS_RESOURCE_ID_VALUE"
       #- name: AKS_REGION
       #  value: "VALUE_AKS_RESOURCE_REGION_VALUE"
       #Uncomment below two lines for ACS clusters and set the cluster names manually. Also comment out the above two lines for ACS clusters
       - name: ACS_RESOURCE_NAME
         value: "my_acs_cluster_name"
       - name: CONTROLLER_TYPE
         value: "ReplicaSet"
       - name: NODE_IP
         valueFrom:
            fieldRef:
              fieldPath: status.hostIP  
       securityContext:
         privileged: true
       ports:
       - containerPort: 25225
         protocol: TCP 
       - containerPort: 25224
         protocol: UDP
       volumeMounts:
        - mountPath: /var/run/host
          name: docker-sock
        - mountPath: /var/log 
          name: host-log
        - mountPath: /var/lib/docker/containers 
          name: containerlog-path
        - mountPath: /etc/kubernetes/host
          name: azure-json-path
        - mountPath: /etc/omsagent-secret
          name: omsagent-secret
          readOnly: true
        - mountPath : /etc/config
          name: omsagent-rs-config
        - mountPath: /etc/config/settings
          name: settings-vol-config
          readOnly: true
        - mountPath: "/mnt/azure"
          name: azurefile-pv
       livenessProbe:
        exec:
         command:
         - /bin/bash
         - -c
         - ps -ef | grep omsagent | grep -v "grep"
        initialDelaySeconds: 60
        periodSeconds: 60
   nodeSelector:
    beta.kubernetes.io/os: linux
    kubernetes.io/role: agent
   volumes:
    - name: docker-sock 
      hostPath:
       path: /var/run
    - name: container-hostname
      hostPath:
       path: /etc/hostname
    - name: host-log
      hostPath:
       path: /var/log
    - name: containerlog-path
      hostPath:
       path: /var/lib/docker/containers
    - name: azure-json-path
      hostPath:
       path: /etc/kubernetes
    - name: omsagent-secret
      secret:
       secretName: omsagent-secret
    - name: omsagent-rs-config
      configMap:
        name: omsagent-rs-config
    - name: settings-vol-config
      configMap:
        name: container-azm-ms-agentconfig
        optional: true
    - name: azurefile-pv
      persistentVolumeClaim:
        claimName: azurefile
---
kind: Service
apiVersion: v1
metadata:
  name: repliceset-service
  namespace: kube-system
spec:
  selector:
    rsName: "omsagent-rs"
  ports:
  - protocol: TCP
    port: 25235
    targetPort: in-rs-tcp
    nodePort: 25235
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: azurefile
provisioner: kubernetes.io/azure-file
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=1000
  - gid=1000
parameters:
  skuName: Standard_LRS
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:azure-cloud-provider
rules:
- apiGroups: ['']
  resources: ['secrets']
  verbs:     ['get','create']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:azure-cloud-provider
roleRef:
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
  name: system:azure-cloud-provider
subjects:
- kind: ServiceAccount
  name: persistent-volume-binder
  namespace: kube-system
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azurefile
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile
  resources:
    requests:
      storage: 10Mi 
```

8. save this file as omsagent.yaml

9. Replace the following values in the file

* VALUE_AKS_RESOURCE_ID -- Resource Id of the cluster
* VALUE_AKS_REGION -- Region the cluster is in
* VALUE_WSID -- base 64 encoded Workspace Id. To get this, go to the portal -- log analytics workspace -- Advanced Settings. REMEMBER: PASTE the base 64 encoded value
* VALUE_KEY -- base 64 encoded Primary Shared Key of the workspace. To get this, go to the portal -- log analytics workspace -- Advanced Settings. REMEMBER: PASTE the base 64 encoded value of the key (which is base 64 encoded to start with)

10. Set the context in your local machine to the AKS cluster
Import-AzAksCredential -ResourceGroupName <clusterResourceGroupName> -Name <clusterName>
11. kubectl apply -f omsagent.yaml

Once the above steps are done, it can take upto 20 minutes for the health related data to show up which can be accessed using the following link:
<https://aka.ms/clusterhealthpreview>

