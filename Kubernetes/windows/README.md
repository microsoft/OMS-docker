## How to use the Kubernetes yaml files for Windows Server

In this folder, we have 2 yaml files.
- OMS Agent deployment yaml file which uses secrets (ws-omsagent-de-secrets.yaml) with secret generation scripts which generates the secrets yaml (omsagentsecret.yaml).

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
						  
- Create your omsagent daemon-set by running ``` kubectl create -f ws-omsagent-de-secrets.yaml ``` 

2. Check to see whether the OMS Agent deployment is running fine. 
   ``` 
   root@ubuntu16-13db:~# kubectl get deployment omsagent
   NAME       DESIRED   CURRENT   NODE-SELECTOR   AGE
   omsagent   1         1         <none>          1h
   ```


