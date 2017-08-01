#!/bin/sh

echo "Enter OMS Workspace ID"
read WORKSPACE_ID
echo "Enter OMS Primary Key"
read SHARED_KEY

WSID_BASE64_ENC=$(echo $WORKSPACE_ID | base64 | tr -d '\n')
KEY_BASE64_ENC=$(echo $SHARED_KEY | base64 | tr -d '\n')
sed -e "s#{{wsid_data}}#${WSID_BASE64_ENC}#g" -e "s#{{key_data}}#${KEY_BASE64_ENC}#g" ./ocp-secret-template.yaml > ocp-secret.yaml

echo "Task completed! secret.yaml file created."
