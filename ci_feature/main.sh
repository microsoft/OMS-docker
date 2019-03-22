#!/bin/bash

if [ -e "/etc/config/kube.conf" ]; then
    cat /etc/config/kube.conf > /etc/opt/microsoft/omsagent/sysconf/omsagent.d/container.conf
else
    sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/sysconf/omsagent.d/container.conf
fi
sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/sysconf/omsagent.d/syslog.conf
sed -i -e 's/^exit 101$/exit 0/g' /usr/sbin/policy-rc.d

#Using the get_hostname for hostname instead of the host field in syslog messages
sed -i.bak "s/record\[\"Host\"\] = hostname/record\[\"Host\"\] = OMS::Common.get_hostname/" /opt/microsoft/omsagent/plugin/filter_syslog.rb

#using /var/opt/microsoft/docker-cimprov/state instead of /var/opt/microsoft/omsagent/state since the latter gets deleted during onboarding
mkdir -p /var/opt/microsoft/docker-cimprov/state

#if [ ! -e "/etc/config/kube.conf" ]; then
  # add permissions for omsagent user to access docker.sock
  #sudo setfacl -m user:omsagent:rw /var/run/host/docker.sock
#fi

# add permissions for omsagent user to access azure.json
sudo setfacl -m user:omsagent:r /etc/kubernetes/host/azure.json

# add permission for omsagent user to log folder. We also need 'x', else log rotation is failing. TODO: Invetigate why 
sudo setfacl -m user:omsagent:rwx /var/opt/microsoft/docker-cimprov/log

DOCKER_SOCKET=/var/run/host/docker.sock
DOCKER_GROUP=docker
REGULAR_USER=omsagent

if [ -S ${DOCKER_SOCKET} ]; then
    echo "getting gid for docker.sock"
    DOCKER_GID=$(stat -c '%g' ${DOCKER_SOCKET})
    echo "creating a local docker group"
    groupadd -for -g ${DOCKER_GID} ${DOCKER_GROUP}
    echo "adding omsagent user to local docker group"
    usermod -aG ${DOCKER_GROUP} ${REGULAR_USER}
fi 

if [[ "$KUBERNETES_SERVICE_HOST" ]];then
	#kubernetes treats node names as lower case
	curl --unix-socket /var/run/host/docker.sock "http:/info" | python -c "import sys, json; print json.load(sys.stdin)['Name'].lower()" > /var/opt/microsoft/docker-cimprov/state/containerhostname
else
	curl --unix-socket /var/run/host/docker.sock "http:/info" | python -c "import sys, json; print json.load(sys.stdin)['Name']" > /var/opt/microsoft/docker-cimprov/state/containerhostname
fi
#check if file was written successfully
cat /var/opt/microsoft/docker-cimprov/state/containerhostname 

#Commenting it for test. We do this in the installer now.
#Setup sudo permission for containerlogtailfilereader
#chmod +w /etc/sudoers.d/omsagent
#echo "#run containerlogtailfilereader.rb for docker-provider" >> /etc/sudoers.d/omsagent
#echo "omsagent ALL=(ALL) NOPASSWD: /opt/microsoft/omsagent/ruby/bin/ruby /opt/microsoft/omsagent/plugin/containerlogtailfilereader.rb *" >> /etc/sudoers.d/omsagent
#chmod 440 /etc/sudoers.d/omsagent

#Disable dsc
#/opt/microsoft/omsconfig/Scripts/OMS_MetaConfigHelper.py --disable
rm -f /etc/opt/microsoft/omsagent/conf/omsagent.d/omsconfig.consistencyinvoker.conf

if [ -z $INT ]; then
  if [ -a /etc/omsagent-secret/DOMAIN ]; then
        /opt/microsoft/omsagent/bin/omsadmin.sh -w `cat /etc/omsagent-secret/WSID` -s `cat /etc/omsagent-secret/KEY` -d `cat /etc/omsagent-secret/DOMAIN`
  elif [ -a /etc/omsagent-secret/WSID ]; then  
        /opt/microsoft/omsagent/bin/omsadmin.sh -w `cat /etc/omsagent-secret/WSID` -s `cat /etc/omsagent-secret/KEY`
  elif [ -a /run/secrets/DOMAIN ]; then
        /opt/microsoft/omsagent/bin/omsadmin.sh -w `cat /run/secrets/WSID` -s `cat /run/secrets/KEY` -d `cat /run/secrets/DOMAIN`
  elif [ -a /run/secrets/WSID ]; then
        /opt/microsoft/omsagent/bin/omsadmin.sh -w `cat /run/secrets/WSID` -s `cat /run/secrets/KEY`
  elif [ -z $DOMAIN ]; then
        /opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $KEY
  else
        /opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $KEY -d $DOMAIN
  fi
else
#To onboard to INT workspace - workspace-id (WSID-not base64 encoded), workspace-key (KEY-not base64 encoded), Domain(DOMAIN-int2.microsoftatlanta-int.com)
#need to be added to omsagent.yaml.
	echo WORKSPACE_ID=$WSID > /etc/omsagent-onboard.conf
	echo SHARED_KEY=$KEY >> /etc/omsagent-onboard.conf
      echo URL_TLD=$DOMAIN >> /etc/omsagent-onboard.conf
	/opt/microsoft/omsagent/bin/omsadmin.sh
fi

#start cron daemon for logrotate
service cron start
#copy config file and start telegraf service
#cp /etc/opt/microsoft/docker-cimprov/telegraf.conf /etc/telegraf/telegraf.conf
#service telegraf start
#get telegraf service status
#service telegraf status

#check if agent onboarded successfully
/opt/microsoft/omsagent/bin/omsadmin.sh -l

#get omsagent and docker-provider versions
dpkg -l | grep omsagent | awk '{print $2 " " $3}'
dpkg -l | grep docker-cimprov | awk '{print $2 " " $3}' 



#telegraf & fluentbit requirements
if [ ! -e "/etc/config/kube.conf" ]; then
      /opt/td-agent-bit/bin/td-agent-bit -c /etc/opt/microsoft/docker-cimprov/td-agent-bit.conf -e /opt/td-agent-bit/bin/out_oms.so &
      telegrafConfFile="/etc/opt/microsoft/docker-cimprov/telegraf.conf"

      #set env vars used by telegraf
      if [ "$AKS_RESOURCE_ID" = ""]
      then
            telemetry_aks_resource_id=""
            telemetry_aks_region=""
            telemetry_cluster_name=""
            telemetry_acs_resource_name=$ACS_RESOURCE_NAME
            telemetry_cluster_type="ACS"
      else
            telemetry_aks_resource_id=$AKS_RESOURCE_ID
            telemetry_aks_region=$AKS_REGION
            telemetry_cluster_name=$AKS_RESOURCE_ID
            telemetry_acs_resource_name=""
            telemetry_cluster_type="AKS"
      fi

      echo "export TELEMETRY_AKS_RESOURCE_ID=$telemetry_aks_resource_id" >> ~/.bashrc
      echo "export TELEMETRY_AKS_REGION=$telemetry_aks_region" >> ~/.bashrc
      echo "export TELEMETRY_CLUSTER_NAME=$telemetry_cluster_name" >> ~/.bashrc
      echo "export TELEMETRY_ACS_RESOURCE_NAME=$telemetry_acs_resource_name" >> ~/.bashrc
      echo "export TELEMETRY_CLUSTER_TYPE=$telemetry_cluster_type" >> ~/.bashrc

      nodename=$(cat /hostfs/etc/hostname)
      echo "nodename: $nodename"
      echo "replacing nodename in telegraf config"
      sed -i -e "s/placeholder_hostname/$nodename/g" $telegrafConfFile

      export HOST_MOUNT_PREFIX=/hostfs
      echo "export HOST_MOUNT_PREFIX=/hostfs" >> ~/.bashrc
      export HOST_PROC=/hostfs/proc
      echo "export HOST_PROC=/hostfs/proc" >> ~/.bashrc
      export HOST_SYS=/hostfs/sys
      echo "export HOST_SYS=/hostfs/sys" >> ~/.bashrc
      export HOST_ETC=/hostfs/etc
      echo "export HOST_ETC=/hostfs/etc" >> ~/.bashrc
      export HOST_VAR=/hostfs/var
      echo "export HOST_VAR=/hostfs/var" >> ~/.bashrc

      aikey=$(echo $APPLICATIONINSIGHTS_AUTH | base64 --decode)
      export TELEMETRY_APPLICATIONINSIGHTS_KEY=$aikey
      echo "export TELEMETRY_APPLICATIONINSIGHTS_KEY=$aikey" >> ~/.bashrc
      
      source ~/.bashrc
      
      #start telegraf
      /usr/bin/telegraf --config /etc/opt/microsoft/docker-cimprov/telegraf.conf &
      
      dpkg -l | grep td-agent-bit | awk '{print $2 " " $3}'
      dpkg -l | grep telegraf | awk '{print $2 " " $3}' 
fi



shutdown() {
	/opt/microsoft/omsagent/bin/service_control stop
	}

trap "shutdown" SIGTERM

sleep inf & wait
