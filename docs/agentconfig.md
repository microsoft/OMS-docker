## Agent data collection settings - Azure Monitor for containers

To configure agent data collection settings, refer to the sample Kubernetes ConfigMap for azure monitor for containers agent [here](https://aka.ms/coinconfigmap).

### Configure your cluster with custom data collection settings

 1. Download the  sample [configMap yaml file](https://aka.ms/coinconfigmap) and save it locally. Then edit the configMap yaml file with your customizations
 2. Create configmap using following kubectl command:
`kubectl apply -f <configmap_yaml_file>`
Example:
`kubectl apply -f container-azm-ms-agentconfig.yaml`
Output will resemble the following:
`configmap "container-azm-ms-agentconfig" created`


#### Following are the data collection settings are configurable through the config map
- `schema-version` - String. Case-sensitive. This is the schema version used by the Azure Monitor agent when parsing this configmap. Currently supported schema-version is v1. Configmaps with other schema versions will be rejected.
- `config-version`- String. Used by customers to keep track of this config file's version in their source control system/repository (max allowed 10 chars, other chars will be truncated)
 - `[log_collection_settings.stdout]`
	 -  `enabled` -  Boolean. This controls if stdout container log collection is enabled. When this is set to true and no namespaces are excluded for stdout log collection (`log_collection_settings.stdout.exclude_namespaces` setting below), stdout logs will be collected from all containers across all pods/nodes in the cluster. In the absense of this configmap, default value is `enabled = true`
	 - `exclude_namespaces` - Comma seperated array of strings. Array of kubernetes namespaces for which stdout logs will not be collected.  This setting is effective only if `log_collection_settings.stdout.enabled` is set to true. In the absense of this configmap, default value is `exclude_namespaces = ["kube-system"]`
 - `[log_collection_settings.stderr]`
	 -   `enabled` - Boolean. This controls if stderr container log collection is enabled. When this is set to true and no namespaces are excluded for stdout log collection (`log_collection_settings.stderr.exclude_namespaces` setting), stderr logs will be collected from all containers across all pods/nodes in the cluster. In the absense of this configmap, default value is `enabled = true`
	 - `exclude_namespaces` - Comma seperated array of strings. Array of kubernetes namespaces for which stderr logs will not be collected.  This setting is effective only if `log_collection_settings.stdout.enabled` is set to true. In the absense of this configmap, default value is `exclude_namespaces = ["kube-system"]`
- [log_collection_settings.env_var]
	- `enabled` - Boolean. This controls if environment variable collection is enabled. When this is set to false, no environment varibale is collection for any container running across all pods/nodes in the cluster.  In the absense of this configmap, default value is `enabled = true`

#### FAQs on configuration settings  Azure Monitor for containers agent
- <b>How do i exclude specific namespaces for stdout log collection ?</b>
`[log_collection_settings.stdout]
	enabled = true
	exclude_namespaces = ["my-namespace-1", "my-namespace-2"]`
	
- <b>How do i turn off stderr log collection cluster-wide ?</b>
  `[log_collection_settings.stderr]
	enabled = false`
	
- <b>How do i disable environment variable collection for specific containers ?</b>
    Follow both steps below.
	- a. Enable environment varibale collection globally by setting the below setting
		  `[log_collection_settings.env_var]
	      enabled - true`
     - b. Disable environment varibale collection for containers for which you do not want to collect environment variables by following the steps [here](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-manage-agent#how-to-disable-environment-variable-collection-on-a-container)
     
 - <b>How long will it take for the config update to become effective</b>
	Config update will take 3-5 minutes to become effective. All omsagent pods in the cluster will restart.
	
- <b>What if my configMap content is incorrect ?</b>
   Agent will use the default configuration if it is not able to parse the configMap. You will also see from the logs for the omsagent pod will have config errors. To see the logs from an agent pod, use the below command:
   `kubectl logs omsagent-fdf58 -n=kube-system`
	Output will show errors like below:
	`***************Start Config Processing********************`
`config::unsupported/missing config schema version - 'v21' , using defaults`

	You can just correct the error in the yaml file, save the file and apply the configMap using the below command:
	`kubectl apply -f container-azm-ms-agentconfig.yaml`

 - <b>How do i know if the config was applied successfully or if there are any errors ? </b>
	 You will see config errors in the logs for the omsagent pod will have config errors. To see the logs from an agent pod, use the below command:
`kubectl logs omsagent-fdf58 -n=kube-system`

	Output will show errors like below:
`***************Start Config Processing********************`
`config::unsupported/missing config schema version - 'v21' , using defaults`

- <b>If i see restarts in my agent pod, how do i determine if the restart is due to config update for the agent ?</b>
	Doing a describe on agent pod will show last state's restart message as 'config changed' as shown below:

	`kubectl describe pod omsagent-fdf58 -n=kube-system`

	Output will resemble the following:
```
	Name:           omsagent-fdf58
	Namespace:      kube-system
	Node:           aks-agentpool-95673144-0/10.240.0.4
	Start Time:     Mon, 10 Jun 2019 15:01:03 -0700
	Labels:         controller-revision-hash=589cc7785d
	                dsName=omsagent-ds
	                pod-template-generation=1
	Annotations:    agentVersion=1.10.0.1
	              dockerProviderVersion=5.0.0-0
	                schema-versions=v1
	Status:         Running
	`IP:             10.244.1.4`
	`Controlled By:  DaemonSet/omsagent`
	`  Containers:`
	  `omsagent:``
	    `Container ID:  docker://7c809b1d271b799bd2b7e4e0c7f5ba27bb3fca07b08fee1572c4ddac5bc14008
	    Image:         mcr.microsoft.com/azuremonitor/containerinsights/ciprod:ci_feature_prod-20190610-043944z-9f70062
	    Image ID:      docker-pullable://mcr.microsoft.com/azuremonitor/containerinsights/ciprod@sha256:0056682df4979e127545a6488fc08baa78c2333e0403756ca7c5aa3a068ffed1
	    Ports:         25225/TCP, 25224/UDP
	    State:         Running
	      Started:     Mon, 10 Jun 2019 17:48:43 -0700
	    Last State:    Terminated
	      Reason:      Error
	      Message:     config changed
 ```
 - <b>If i already have a config map created for my cluster, how do i update it with newer config ? </b>
 You can edit the configmap file that you have in your sourcecontrol for the previous config and then apply using kubectl with the following command:
kubectl apply -f <configmap_yaml_file>
Example:
`kubectl apply -f container-azm-ms-agentconfig.yaml`
Output will resemble the following:
`configmap "container-azm-ms-agentconfig" updated`
- <b> How do i find what are the supported schema version  for the agent version that i am using? </b>
Supported config schema verisons are available as pod annotation (schema-versions) on the agent pod. You can see thwm with the following command.

	`kubectl describe pod omsagent-fdf58 -n=kube-system`
    
	 Output will resemble the following showing the annotation `schema-versions`
    

```
	Name:           omsagent-fdf58
	Namespace:      kube-system
	Node:           aks-agentpool-95673144-0/10.240.0.4
	Start Time:     Mon, 10 Jun 2019 15:01:03 -0700
	Labels:         controller-revision-hash=589cc7785d
	                dsName=omsagent-ds
	                pod-template-generation=1
	Annotations:    agentVersion=1.10.0.1
	              dockerProviderVersion=5.0.0-0
	                schema-versions=v1 
```
