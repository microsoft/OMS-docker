#!/bin/bash
set -e

# Note - This script used in the pipeline as inline script

if [ -z $ACR_NAME ]; then
  echo "-e error value of ACR_NAME variable shouldnt be empty. check release variables"
  exit 1
fi

if [ -z $IMAGE_TAG ]; then
  echo "-e error IMAGE_TAG shouldnt be empty. check release variables"
  exit 1
fi

echo "Installing crane"
#Install crane
echo "Installing crane"
wget -O crane.tar.gz https://github.com/google/go-containerregistry/releases/download/v0.4.0/go-containerregistry_Linux_x86_64.tar.gz
if [ $? -eq 0 ]; then         
   echo "crane downloaded successfully"
else     
   echo "-e error crane download failed"
   exit 1
fi 
tar xzvf crane.tar.gz
echo "Installed crane"

# echo "installing podman"
# echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_'"$(lsb_release -sr)"'/ /' | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
# curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_"$(lsb_release -sr)"/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg > /dev/null
# apt-get update -y
# apt-get upgrade -y
# apt-get install podman -y
# export podmanVersion="$(echo $( podman version --format '{{.Version}}'))"

# if [ ! -z "$podmanVersion" ]; then
#    	echo "installing podman completed"
# else
# 	echo "installing podman failed"
#     exit 1
# fi

echo "az login using managed identity"
az login --identity
if [ $? -eq 0 ]; then
  echo "Logged in successfully"
else
  echo "-e error failed to login to az with managed identity credentials"
  exit 1
fi

echo "Getting acr credentials"
TOKEN_QUERY_RES=$(az acr login -n "$ACR_NAME" -t)
TOKEN=$(echo "$TOKEN_QUERY_RES" | jq -r '.accessToken')
if [ -z $TOKEN ]; then
  echo "-e error failed to get az acr login token"
  exit 1
fi
echo "az acr login"


DESTINATION_ACR=$(echo "$TOKEN_QUERY_RES" | jq -r '.loginServer')
if [ -z $DESTINATION_ACR ]; then
  echo "-e error value of DESTINATION_ACR shouldnt be empty"
  exit 1
fi

./crane auth login "$DESTINATION_ACR" -u "00000000-0000-0000-0000-000000000000" -p "$TOKEN"

#Prepare tarball and push to acr
gunzip solutionimage.tar.gz

echo "Pushing file solutionimage.tar.gz to public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
./crane push *.tar "public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
