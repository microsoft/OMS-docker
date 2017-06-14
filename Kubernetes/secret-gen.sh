#!/bin/sh

echo "Enter OMS Workspace ID"
read WORKSPACE_ID
echo "Enter OMS Primary Key"
read SHARED_KEY

WSID_BASE64_ENC=$(echo $WORKSPACE_ID | base64 | tr -d '\n')
KEY_BASE64_ENC=$(echo $SHARED_KEY | base64 | tr -d '\n')
sed -e "s#{{wsid_data}}#${WSID_BASE64_ENC}#g" -e "s#{{key_data}}#${KEY_BASE64_ENC}#g" ./secret-template.yaml > omsagentsecret.yaml
#sed -e "s#{{key_data}}#${KEY_BASE64_ENC}#g" ./secret-template.yaml > secret.yaml

echo "Task completed! secret.yaml file created."