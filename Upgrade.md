# How to Upgrade 

- If you are using the OMS Agent for Linux, please follow the instruction for the [OMS Agent for Linux.](https://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/OMS-Agent-for-Linux.md)

- If you are using the containerized Container Solution, please go thru the following instructions: 
	- Stop the containerized Container Solution. 
	``` docker stop omsagent```
	- Remove the container name.
	```docker rm omsagent```
	- Remove container image.
	```docker rmi microsoft/oms```
	- Follow the new instruction to run the latest containerized [Container Solution](https://github.com/microsoft/OMS-docker#to-use-oms-for-all-containers-on-a-container-host)
