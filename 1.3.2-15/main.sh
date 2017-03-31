#!/bin/bash -x

sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/sysconf/omsagent.d/container.conf
sed -i -e 's/^exit 101$/exit 0/g' /usr/sbin/policy-rc.d

#Using the get_hostname for hostname instead of the host field in syslog messages
sed -i.bak "s/record\[\"Host\"\] = hostname/record\[\"Host\"\] = OMS::Common.get_hostname/" /opt/microsoft/omsagent/plugin/filter_syslog.rb


#service omid start
/opt/omi/bin/service_control start

if [ -z $INT ]; then
	/opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $KEY
else
	echo WORKSPACE_ID=$WSID > /etc/omsagent-onboard.conf
	echo SHARED_KEY=$KEY >> /etc/omsagent-onboard.conf
	/opt/microsoft/omsagent/bin/omsadmin.sh
fi

#service omsagent start
/opt/microsoft/omsagent/bin/service_control start

#/opt/microsoft/omsconfig/Scripts/OMS_MetaConfigHelper.py --disable
#rm -f /etc/opt/microsoft/omsagent/conf/omsagent.d/omsconfig.consistencyinvoker.conf

shutdown() {
	/opt/omi/bin/service_control stop
	/opt/microsoft/omsagent/bin/service_control stop
	}

trap "shutdown" SIGTERM

sleep inf & wait
