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

echo "installing podman"
echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_'"$(lsb_release -sr)"'/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_"$(lsb_release -sr)"/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_stable.gpg > /dev/null
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install podman -y
export podmanVersion="$(echo $( podman version --format '{{.Version}}'))"

if [ ! -z "$podmanVersion" ]; then
   	echo "installing podman completed"
else
	echo "installing podman failed"
    exit 1
fi

echo "az login using managed identity"
az login --identity
if [ $? -eq 0 ]; then
  echo "Logged in successfully"
else
  echo "-e error failed to login to az with managed identity credentials"
  exit 1
fi

echo "az acr login"
az acr login --name $ACR_NAME
if [ $? -eq 0 ]; then
  echo "Logged in successfully"
else
  echo "-e error failed to login to acr ${ACR_NAME}"
  exit 1
fi

echo "loading image tarball"
IMAGE_NAME=$(podman load -i image.tar.gz)
echo IMAGE_NAME: $IMAGE_NAME
if [ $? -ne 0 ]; then
  echo "-e error, on loading tarball from image.tar.gz"
  exit 1
else
  echo "successfully loaded image tarball"
fi

IMAGE_NAME=$(echo $IMAGE_NAME | tr -d '"' | tr -d "[:space:]")
IMAGE_NAME=${IMAGE_NAME#$prefix}
echo "*** trimmed image name-:${IMAGE_NAME}"
echo "tagging the image $IMAGE_NAME as public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
podman tag $IMAGE_NAME public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}

if [ $? -ne 0 ]; then
  echo "-e error  tagging the image $IMAGE_NAME as public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
  exit 1
else
  echo "successfully tagged the image $IMAGE_NAME as public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
fi

echo "pushing public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
podman push public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}
if [ $? -ne 0 ]; then
  echo "-e error  on pushing the image public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
  exit 1
else
  echo "Successfully pushed the image public/azuremonitor/containerinsights/ciprod:${IMAGE_TAG}"
fi
