## How to use the Kubernetes yaml files

In this folder, we have 3 yaml files. 
- Default OMS Agent Daemon-set which does not have secrets (omsagent.yaml)
- OMS Agent Daemon-set yaml file which uses secrets (omsagent-ds-secrets.yaml) with secret generation scripts which generates the secrets yaml (omsagentsecret.yaml). 

You can select to create omsagent daemonsets with or without secrets. Here are the instructions: 

### Without Secret
1. For the Default OMS Agent Daemon-set yaml file, please make sure to replace the `<WSID>` and `<KEY>` to your WSID and KEY. 
Copy file to your master node and run 
 ```kubectl create -f omsagent.yaml ```


### With Secret
1. To use OMS Agent Daemon-set using Secrets, create the secrets first. 

  - Copy the script and secret template file and make sure they are on the same directory. 
	- secret generating script - secret-gen.sh
	- secret template - secret-template.yaml
  - Run the script. The script will ask for the OMS Workspace ID and Primary Key. Please insert that and the script will create a secret yaml file so you can run it.   

   ```
   #> sudo bash ./secret-gen.sh 
   ```

   - Create the secrets pod by running the following: 
  ``` kubectl create -f omsagentsecret.yaml ```
 
   - To check, run the following: 

   ``` 
   root@ubuntu16-13db:~# kubectl get secrets
   NAME                  TYPE                                  DATA      AGE
   default-token-gvl91   kubernetes.io/service-account-token   3         50d
   omsagent-secret       Opaque                                2         1d
   root@ubuntu16-13db:~# kubectl describe secrets omsagent-secret
   Name:           omsagent-secret
   Namespace:      default
   Labels:         <none>
   Annotations:    <none>

   Type:   Opaque

   Data
   ====
   WSID:   36 bytes
   KEY:    88 bytes 
   ```
 
  - Create your omsagent daemon-set by running ``` kubectl create -f omsagent-ds-secrets.yaml ```

2. Check to see whether the OMS Agent daemon-set is running fine. 
   ``` 
   root@ubuntu16-13db:~# kubectl get ds omsagent
   NAME       DESIRED   CURRENT   NODE-SELECTOR   AGE
   omsagent   3         3         <none>          1h
   ```
