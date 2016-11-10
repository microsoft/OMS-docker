# How to Upgrade 
- If you are using the OMS Agent for Linux, please follow the instruction for the [OMS Agent for Linux.](http://) 
    - Before upgrade OMS Agent, remove the universal docker settings mentioned [here.](https://github.com/Microsoft/OMS-docker/blob/keikoacs/OlderVersionREADME.md#setting-up) You may need to restart your docker service for this. 

- If you are using the containerized Container Solution, please go thru the following instructions: 
	- Stop the containerized Container Solution. 
	``` docker stop omsagent```
	- Remove the container name.
	```docker rm omsagent```
	- Remove container image.
	```docker rmi microsoft/oms```
	- Remove the universal docker settings mentioned [here.](https://github.com/Microsoft/OMS-docker/blob/keikoacs/OlderVersionREADME.md#setting-up) You may need to restart your docker service for this. 
	- Follow the new instruction to run the latest containerized Container Solution
