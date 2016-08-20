# Trying the container solution for Microsoft Operations Management Suite

The Microsoft Operations Management Suite (OMS) is a software-as-a-service offering from Microsoft that allows Enterprise IT to manage any hybrid cloud. It offers log analytics, automation, backup and recovery, and security and compliance.  Sign up for a free account at [http://mms.microsoft.com](http://mms.microsoft.com) or read more about here: [https://www.microsoft.com/en-us/server-cloud/operations-management-suite/overview.aspx](https://www.microsoft.com/en-us/server-cloud/operations-management-suite/overview.aspx)

This container solution will generate a container which will runs OMS agent within. This is for Linux OS which has restriction in installing the Operations Management Suite Agent directly. However, it can also be used with other support Linux OS as well.

This is a public preview product. 

### Supported Linux Operating Systems and Docker:

- Docker 1.8 thru 1.12.1

- An x64 version of Linux OS
	- Ubuntu 14.04 LTS, 15.10, 16.04 LTS
	- CoreOS(stable)
	- Amazon Linux 2016.03
	- openSUSE 13.2
	- CentOS 7
	- SLES 12
	- RHEL 7.2

## Setting up
As a pre-requisite, docker must be running prior to this installation. If you have installed before running docker, please re-install OMS Agent. For more information about docker, please go to https://www.docker.com/.


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

#### Settings on container host - systemd drop-in units
- If you want to use the drop-in units, please modify your conf file in `/etc/systemd/system/docker.service.d`.

Add the following in `[Service]`. 
```
Environment="DOCKER_OPTS=--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
```
Make sure you add $DOCKER_OPTS in "ExecStart=/usr/bin/docker daemon" within your docker.service file.

example)
```
[Service]
Restart=always
StartLimitInterval=0
Environment="DOCKER_OPTS=--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
RestartSec=15
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --storage-driver=overlay $DOCKER_OPTS
```
- Restart docker service.
```
systemctl restart docker.service
```
For more information, please go to [Control and configure Docker with systemd](https://docs.docker.com/engine/admin/systemd/) on Docker website.

#### Settings on container host - Upstart
- Edit /etc/default/docker and add this line:
```
DOCKER_OPTS="--log-driver=fluentd --log-opt fluentd-address=localhost:25225"
```
- Save the file and then restart the docker service and oms service:
```
sudo service docker restart
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
$>sudo docker run --privileged -d -v /var/run/docker.sock:/var/run/docker.sock -e WSID="your workspace id" -e KEY="your key" -h=`hostname` -p 127.0.0.1:25225:25225 --name="omsagent" --restart=always microsoft/oms
```

### If you are switching from the installed agent to the container

If you previously used the directly installed agent and want to switch to using the container, you must remove the omsagent.
See [Steps to install the OMS Agent for Linux](https://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/OMS-Agent-for-Linux.md)

## What now?
Once you're set up, we'd like you to try the following scenarios and play around with the system.

[More Container Management Scenarios](http://github.com/Microsoft/OMS-Agent-for-Linux/blob/master/docs/Docker-Instructions.md#overview)

## Let us know!!!
What works? What is missing? What else do you need for this to be useful for you? Let us know at OMSContainers@microsoft.com.
