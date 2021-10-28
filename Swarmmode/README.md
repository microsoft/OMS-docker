To run OMS Agent as a global service on Docker Swarm, please log onto your master node and run the following command: 

```
docker service create --name omsagent --mode global --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock  --mount type=bind,source=/var/lib/docker/containers,destination=/var/lib/docker/containers -e WSID="<WORKSPACE ID>" -e KEY="<PRIMARY KEY>" -p 25225:25225 -p 25224:25224/udp --restart-condition=on-failure mcr.microsoft.com/azuremonitor/containerinsights/ciprod:microsoft-oms-latest
```
