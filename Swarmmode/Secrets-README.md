## How to create Docker Swarm OMS Agent secrets

### Following instructions are to how to create 
1. Run the following on the master node. 

```
echo "WSID" | docker secret create WSID -
echo "KEY" | docker secret create KEY -
```

2. Check whether secrets are created properly. 

``` root@swarmm-master-13957614-0:/run# docker secret ls
ID                          NAME                CREATED             UPDATED
j2fj153zxy91j8zbcitnjxjiv   WSID                43 minutes ago      43 minutes ago
l9rh3n987g9c45zffuxdxetd9   KEY                 38 minutes ago      38 minutes ago
```

3. Run the following command to mount the secrets to the containerized OMS Agent. 

``` docker service create  --name omsagent --mode global  --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock --secret source=WSID,target=WSID --secret source=KEY,target=KEY  -p 25225:25225 -p 25224:25224/udp --restart-condition=on-failure microsoft/oms:test1 ```
