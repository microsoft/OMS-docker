#!/bin/bash

service omid start

if [ -z $INT ]; then
	/opt/microsoft/omsagent/bin/omsadmin.sh -w $WSID -s $KEY
else
	echo WORKSPACE_ID=$WSID > /etc/omsagent-onboard.conf
	echo SHARED_KEY=$KEY >> /etc/omsagent-onboard.conf
	echo URL_TLD=int2.microsoftatlanta-int >> /etc/omsagent-onboard.conf
	/opt/microsoft/omsagent/bin/omsadmin.sh
fi

service omsagent start

sleep inf
