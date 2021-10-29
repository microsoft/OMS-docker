## How to use the OMS Agent daemon-set for Redhat Openshift yaml files

In this folder, you will have two daemon-set files: 
- ocp-omsagent.yaml (default daemon-set)
- ocp-ds-omsagent.yaml (daemon-set which uses secrets)

### Deploying OMS Agent daemon-sets without using secrets

1. Run the following commands to create a project for OMS and set user account. 

```
oc adm new-project omslogging --node-selector='zone=default'
oc project omslogging
oc create serviceaccount omsagent
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:omslogging:omsagent
oc adm policy add-scc-to-user privileged system:serviceaccount:omslogging:omsagent
```

2. Log on to the OpenShift master node and copy `ocp-omsagent.yaml`. Replace `<WSID>` and `<KEY>` section of the daemon-set yaml file with your OMS Workspace ID and Primary Key. Deploy the daemon-set by runining the following command:
``` oc create -f ocp-omsagent.yaml ```

3. To check whether everything is working fine, type the following command: 
``` 
oc describe daemonset omsagent
oc get pods
```

### Deploying OMS Agent daemon-sets with secrets

1. Run the following commands to create a project for OMS and set user account. 

```
oc adm new-project omslogging --node-selector='zone=default'
oc project omslogging
oc create serviceaccount omsagent
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:omslogging:omsagent
oc adm policy add-scc-to-user privileged system:serviceaccount:omslogging:omsagent
```

2. Log on to the Openshift master node and copy the secret generating script and secret template file. Secret generating script will ask for your OMS Workspace ID `<WSID>` and Primary Key `<KEY>`. 
- secretgen.sh ( secret generating script) 
- ocp-secret-template.yaml (secret template file)

3. The script will generate `ocp-secret.yaml` file. Deploy the secret file. 
```
oc create -f ocp-secret.yaml
```

Check with ``` oc describe secret omsagent-secret ```. 

4. Copy the OMS Agent Daemon-set yaml file `ocp-ds-omsagent.yaml` to the master node. Deploy the OMS Agent daemon-set yaml file. 
``` 
oc create -f ocp-ds-omsagent.yaml
```

And check with ``` oc describe ds oms ```
