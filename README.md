# Trying the container solution for Microsoft Operations Management Suite

The Microsoft Operations Management Suite (OMS) is a software-as-a-service offering from Microsoft that allows Enterprise IT to manage any hybrid cloud. It offers log analytics, automation, backup and recovery, and security and compliance.  Sign up for a free account at [http://mms.microsoft.com](http://mms.microsoft.com) or read more about here: [https://www.microsoft.com/en-us/server-cloud/operations-management-suite/overview.aspx](https://www.microsoft.com/en-us/server-cloud/operations-management-suite/overview.aspx)

This container solution will generate a container which will runs OMS agent within. This is for Linux OS which has restriction in installing the Operations Management Suite Agent directly. However, it can also be used with other support Linux OS as well.

### Supported Linux Operating Systems, Docker, and ACS Mesosphere DC/OS:

- Docker 1.11 thru 1.13
- Docker CE and EE v17.06+

- An x64 version of Linux OS
	- Ubuntu 14.04 LTS, 16.04 LTS
	- CoreOS(stable)
	- Amazon Linux 2016.09.0
	- openSUSE 13.2
	- openSUSE LEAP 42.2
	- CentOS 7.2, 7.3
	- SLES 12
	- RHEL 7.2, 7.3

- ACS Mesosphere DC/OS 1.7.3, 1.8.8, 1.9
- ACS Kubernetes 1.4.5, 1.6+ 
- ACS Docker Swarm
- Redhat OpenShift (OCP) 3.4, 3.5 

### Support for Windows Operation Systems
This site is only for Linux. 

For any information about Windows Operating System, please go [here.](https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-containers#windows-container-hosts) 

### Release Note
Update Information are [here.](https://github.com/Microsoft/OMS-docker/blob/master/ReleaseNote.md)

## Setting up
As a pre-requisite, docker must be running prior to this installation. If you have installed before running docker, please re-install OMS Agent. For more information about docker, please go to https://www.docker.com/.

This set up is not for ACS Mesosphere DC/OS or ACS Kubernetes. 
- For more information on Mesosphere DC/OS, please see [here.](https://docs.microsoft.com/en-us/azure/container-service/container-service-monitoring-oms)
- For Kubernetes, please see [here.](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-oms) yaml file for the daemon-set is [here.](https://github.com/Microsoft/OMS-docker/tree/master/Kubernetes)
- For Docker Swarm, please see [here.](https://github.com/Microsoft/OMS-docker/tree/master/Swarmmode)

- For Redhat OpenShift, please see [here.](https://github.com/Microsoft/OMS-docker/tree/master/OpenShift)
This set up provides a containerized Container Solution Agent (OMS Agent for Linux). If you are interested in a full OMS Agent for linux with Container Solution, please go [here.](https://github.com/Microsoft/OMS-Agent-for-Linux)


### To use OMS for all containers on a container host

- Start the OMS container:
```
$>sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/log:/var/log -v /var/lib/docker/containers:/var/lib/docker/containers -e WSID="your workspace id" -e KEY="your key" -p 127.0.0.1:25225:25225 -p 127.0.0.1:25224:25224/udp --name="omsagent" -h=`hostname` --restart=always mcr.microsoft.com/azuremonitor/containerinsights/ciprod:microsoft-oms-latest
```

### To use OMS for all containers on a container host for FairFax OMS Workspace

- Start the OMS container on FairFax OMS workspace:
```
$>sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/log:/var/log -v /var/lib/docker/containers:/var/lib/docker/containers -e WSID="your workspace id" -e KEY="your key" -e DOMAIN="opinsights.azure.us" -p 127.0.0.1:25225:25225 -p 127.0.0.1:25224:25224/udp --name="omsagent" -h=`hostname` --restart=always mcr.microsoft.com/azuremonitor/containerinsights/ciprod:microsoft-oms-latest
```

### If you are switching from the installed agent to the container

If you previously used the directly installed agent and want to switch to using the container, you must remove the omsagent.
See [Steps to install the OMS Agent for Linux](https://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/OMS-Agent-for-Linux.md)

#### If you have an older version of Docker and would want to still use OMS Container Solution to monitor your data go [here.](https://github.com/Microsoft/OMS-docker/blob/master/OlderVersionREADME.md)

### Upgrade
You can upgrade to a newer version of the agent. See [here.](https://github.com/Microsoft/OMS-docker/blob/master/Upgrade.md)

## What now?
Once you're set up, we'd like you to try the following scenarios and play around with the system.

[More Container Management Scenarios](http://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/Docker-Instructions.md#overview)

## Let us know!!!
What works? What is missing? What else do you need for this to be useful for you? Let us know at OMSContainers@microsoft.com.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct]
(https://opensource.microsoft.com/codeofconduct/).  For more
information see the [Code of Conduct FAQ]
(https://opensource.microsoft.com/codeofconduct/faq/) or contact
[opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.
