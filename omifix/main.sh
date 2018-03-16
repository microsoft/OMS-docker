#!/bin/bash

sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/sysconf/omsagent.d/container.conf
sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/sysconf/omsagent.d/syslog.conf
sed -i -e 's/^exit 101$/exit 0/g' /usr/sbin/policy-rc.d

#Using the get_hostname for hostname instead of the host field in syslog messages
sed -i.bak "s/record\[\"Host\"\] = hostname/record\[\"Host\"\] = OMS::Common.get_hostname/" /opt/microsoft/omsagent/plugin/filter_syslog.rb

#using /var/opt/microsoft/docker-cimprov/state instead of /var/opt/microsoft/omsagent/state since the latter gets deleted during onboarding
mkdir -p /var/opt/microsoft/docker-cimprov/state
if [[ "$KUBERNETES_SERVICE_HOST" ]];then
	#kubernetes treats node names as lower case
	curl --unix-socket /var/run/docker.sock "http:/info" | python -c "import sys, json; print json.load(sys.stdin)['Name'].lower()" > /var/opt/microsoft/docker-cimprov/state/containerhostname
else
	curl --unix-socket /var/run/docker.sock "http:/info" | python -c "import sys, json; print json.load(sys.stdin)['Name']" > /var/opt/microsoft/docker-cimprov/state/containerhostname
fi
#check if file was written successfully
cat /var/opt/microsoft/docker-cimprov/state/containerhostname 

#service omid start
/opt/omi/bin/omiserver --configfile=/etc/opt/omi/conf/omiserver.conf -d

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
	echo WORKSPACE_ID=$WSID > /etc/omsagent-onboard.conf
	echo SHARED_KEY=$KEY >> /etc/omsagent-onboard.conf
	/opt/microsoft/omsagent/bin/omsadmin.sh
fi

#Reload OMI Server
 #/opt/omi/bin/omiserver -s
 #/opt/omi/bin/omiserver --configfile=/etc/opt/omi/conf/omiserver.conf -d
#Test successful install of docker-provider
 /opt/omi/bin/omicli id
 /opt/omi/bin/omicli ei root/cimv2 Container_HostInventory

#check if agent onboarded successfully
/opt/microsoft/omsagent/bin/omsadmin.sh -l

#get omsagent and docker-provider versions
dpkg -l | grep omsagent | awk '{print $2 " " $3}'
dpkg -l | grep omi | awk '{print $2 " " $3}'
dpkg -l | grep docker-cimprov | awk '{print $2 " " $3}' 

#/opt/microsoft/omsconfig/Scripts/OMS_MetaConfigHelper.py --disable
#rm -f /etc/opt/microsoft/omsagent/conf/omsagent.d/omsconfig.consistencyinvoker.conf

shutdown() {
	/opt/omi/bin/service_control stop
	/opt/microsoft/omsagent/bin/service_control stop
	}

trap "shutdown" SIGTERM

sleep inf & wait
