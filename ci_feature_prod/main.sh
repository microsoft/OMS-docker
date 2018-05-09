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
	#dump kubernetes version to a file for telemetry purpose
	curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://$KUBERNETES_SERVICE_HOST/api/v1/nodes | python -c "import sys, json; data=json.load(sys.stdin); kubeletversion = data['items'][0]['status']['nodeInfo']['kubeletVersion']; print kubeletversion;" > /var/opt/microsoft/docker-cimprov/state/kubeletversion
	cat /var/opt/microsoft/docker-cimprov/state/kubeletversion
else
	curl --unix-socket /var/run/docker.sock "http:/info" | python -c "import sys, json; print json.load(sys.stdin)['Name']" > /var/opt/microsoft/docker-cimprov/state/containerhostname
fi
#check if file was written successfully
cat /var/opt/microsoft/docker-cimprov/state/containerhostname 

#dump OMS agent Image tag for telemetry purpose
#step-1 dump the oms agent container imageID
 curl --unix-socket /var/run/docker.sock "http:/containers/json" | python -c "import sys, json; data=json.load(sys.stdin); omscontainer=[item for item in data if item['Image'].startswith('microsoft/oms@sha256:')]; print omscontainer[0]['ImageID'];" > /var/opt/microsoft/docker-cimprov/state/omscontainerimageid
 cat /var/opt/microsoft/docker-cimprov/state/omscontainerimageid 
#step-2 dump the oms agent repo tags from imageID to be picked up by telemetry
 if [ -e "/var/opt/microsoft/docker-cimprov/state/omscontainerimageid" ]; then
    curl --unix-socket /var/run/docker.sock "http:/images/json" | python -c "import sys, json; data=json.load(sys.stdin); imageID = open('/var/opt/microsoft/docker-cimprov/state/omscontainerimageid', 'r').read().encode('ascii','ignore'); omscontainer=[item for item in data if imageID.rstrip('\n') in item['Id']]; print omscontainer[0]['RepoTags'];" > /var/opt/microsoft/docker-cimprov/state/omscontainertag
    cat /var/opt/microsoft/docker-cimprov/state/omscontainertag
 fi

#Commenting it for test. We do this in the installer now.
#Setup sudo permission for containerlogtailfilereader
#chmod +w /etc/sudoers.d/omsagent
#echo "#run containerlogtailfilereader.rb for docker-provider" >> /etc/sudoers.d/omsagent
#echo "omsagent ALL=(ALL) NOPASSWD: /opt/microsoft/omsagent/ruby/bin/ruby /opt/microsoft/omsagent/plugin/containerlogtailfilereader.rb *" >> /etc/sudoers.d/omsagent
#chmod 440 /etc/sudoers.d/omsagent

#Disable dsc
/opt/microsoft/omsconfig/Scripts/OMS_MetaConfigHelper.py --disable
rm -f /etc/opt/microsoft/omsagent/conf/omsagent.d/omsconfig.consistencyinvoker.conf

#service omid start
/opt/omi/bin/omiserver -s
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

#Hack for omi upgrade
 
 /opt/omi/bin/omicli id
 /opt/omi/bin/omicli ei root/cimv2 Container_HostInventory

#start cron daemon for logrotate
service cron start

#check if agent onboarded successfully
/opt/microsoft/omsagent/bin/omsadmin.sh -l

#get omsagent and docker-provider versions
dpkg -l | grep omi | awk '{print $2 " " $3}'
dpkg -l | grep omsagent | awk '{print $2 " " $3}'
dpkg -l | grep docker-cimprov | awk '{print $2 " " $3}' 


shutdown() {
	/opt/omi/bin/service_control stop
	/opt/microsoft/omsagent/bin/service_control stop
	}

trap "shutdown" SIGTERM

sleep inf & wait
