## How to use the OMS Agent daemon-set for Redhat Openshift yaml files

In this folder, you will have a ocp-openshift.yaml file. 

1. Prior to deploying the daemon-set, you will need to change security permissions for OMS Agent. On the master node, performance the following command. 

```
oadm new-project omslogging --node-selector='zone=default'
oc project omslogging
oc create serviceaccount omsagent
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:omslogging:omsagent
oadm policy add-scc-to-user privileged system:serviceaccount:omslogging:omsagent
```

2. To deploy the daemon-set, run the following command:
``` oc create -f ocp-omsagent.yaml ```

3. To check whether everything is working fine, type the following command: 
``` 
oc describe daemonset omsagent
oc get pods
```
