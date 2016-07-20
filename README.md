# Trying the container solution pack for Microsoft Operations Management Suite

The Microsoft Operations Management Suite (OMS) is a software-as-a-service offering from Microsoft that allows Enterprise IT to manage any hybrid cloud. It offers log analytics, automation, backup and recovery, and security and compliance.  Sign up for a free account at [http://mms.microsoft.com](http://mms.microsoft.com) or read more about here: [https://www.microsoft.com/en-us/server-cloud/operations-management-suite/overview.aspx](https://www.microsoft.com/en-us/server-cloud/operations-management-suite/overview.aspx)

This container solution pack will generate a container which will runs OMS agent within. This is for Linux OS which has restriction in installing the Operations Management Suite Agent directly. However, it can also be used with other support Linux OS as well.

## Joining the private preview

You must be a member of the private preview to use this feature. To join, drop us a line at OMSContainers@microsoft.com.

### Supported Linux Operating Systems and Docker:
- Docker 1.8 and above
- An x64 version of Linux OS
	- Ubuntu 14.04, 15.04
	- CoreOS(stable)
	- Amazon Linux 2016.03
	- SUSE 13.2
	- CentOS 7
	- SLES 12

## Setting up
As a pre-requisite, docker must be running prior to this installation. If you have installed before running docker, please re-install OMS Agent. For more information about docker, please go to https://www.docker.com/.

You have two choices for how to capture your container information. You can use OMS for all containers on a container host, or designate specific containers to send information to OMS.

#### Settings on container host - systemd
- Edit docker.service to add the following:
```
[Service]
...
Environment="DOCKER_OPTS=--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
...
```
Make sure you add $DOCKER_OPTS in "ExecStart=/usr/bin/docker daemon" within your docker.service file.
example)
```
[Service]
Environment="DOCKER_OPTS=--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
ExecStart=/usr/bin/docker daemon -H fd:// $DOCKER_OPTS
```
- Restart docker service.
```
systemctl restart docker.service
```
#### Settings on container host - Upstart
- Edit /etc/default/docker and add this line:
```
DOCKER_OPTS="--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
```
- Save the file and then restart the docker service and oms service:
```
sudo service docker restart
sudo service omsagent restart
```
#### Settings on container host - Amazon Linux
- Edit /etc/sysconfig/docker to add the following:
```
OPTIONS="--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
```
-Save the file and then restart docker service. 
```
sudo service docker restart
```

### To use OMS for all containers on a container host

- Start the OMS container:
```
$>sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -e WSID="your workspace id" -e KEY="your key" -h=`hostname` -p 127.0.0.1:25224:25224/udp -p 127.0.0.1:25225:25225 --name="omsagent" --log-driver=none --restart=always microsoft/oms
```
### To use OMS for specific containers on a host

- Start the OMS container:
```
$>sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -e WSID="your workspace id" -e KEY="your key" -h=`hostname` -p 127.0.0.1:25224:25224/udp -p 127.0.0.1:25225:25225 --name="omsagent" --log-driver=fluentd --log-opt fluentd-address=localhost:25225 --restart=always microsoft/oms
```
Then start containers you'd like to be monitored.

### If you are switching from the installed agent to the container

If you previously used the directly installed agent and want to switch to using the container, you must remove the omsagent first by running the installer with the -purge option.


## What now?
Once you're set up, we'd like you to try the following scenarios and play around with the system.

[More Container Management Scenarios](http://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/Docker-Instructions.md#overview)

## Let us know!!!
What works? What is missing? What else do you need for this to be useful for you? Let us know at OMSContainers@microsoft.com.
