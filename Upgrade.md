# How to Upgrade 

- If you are using the OMS Agent for Linux, please follow the instruction for the [OMS Agent for Linux.](https://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/OMS-Agent-for-Linux.md)

- If you are using the containerized Container Solution, please go thru the following instructions: 
	- Stop the containerized Container Solution. 
	``` docker stop omsagent```
	- Remove the container name.
	```docker rm omsagent```
	- Remove container image.
	```docker rmi mcr.microsoft.com/azuremonitor/containerinsights/ciprod:microsoft-oms-latest```
	- Follow the new instruction to run the latest containerized [Container Solution](https://github.com/microsoft/OMS-docker#to-use-oms-for-all-containers-on-a-container-host)

# Check Existing Version

To check the full SHA256 id of the image you have on your machine:
- Run `docker images` to get the image id for `mcr.microsoft.com/azuremonitor/containerinsights/ciprod:microsoft-oms-latest` or `microsoft/oms` if you are using an older version
- Run `docker inspect image <imageid>` to see the full `Id` for the image (this is the first value in the result).