#!/bin/bash

service omid start

if [ -z $INT ]; then
	/opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $KEY
else
	echo WORKSPACE_ID=$WSID > /etc/omsagent-onboard.conf
	echo SHARED_KEY=$KEY >> /etc/omsagent-onboard.conf
	/opt/microsoft/omsagent/bin/omsadmin.sh
fi

sed -i -e 's/^  bind 127.0.0.1$/  bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/conf/omsagent.conf
sed -i -e 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/opt/microsoft/omsagent/conf/omsagent.d/container.conf

service omsagent start

/opt/microsoft/omsconfig/Scripts/OMS_MetaConfigHelper.py --disable
rm -f /etc/opt/microsoft/omsagent/conf/omsagent.d/omsconfig.consistencyinvoker.conf

sleep inf
