# Windows AKS Log Containerized Agent

## How is the windows agent built

There are multiple dependencies that are needed to build the windows container log image

1. Certificate Generator -- create a self signed certificate and register with the OMS workspace
2. Configuration files for fluent, fluent-bit and oms outplut plugin
3. oms output plugin for fluent-bit
4. Ruby scripts for configuration parsing
5. Powershell scripts for setup and running the container on an AKS windows node

### Certificate Generator

This code is checked into the OMS-docker repo [here](https://github.com/microsoft/OMS-docker/tree/dilipr/winakslog/Kubernetes/windows/CertificateGenerator)

- If any change needs to be made here

  - Open the folder in vscode and make your edits
  - Run the following commands to install dependencies, build and publish

         dotnet add package Newtonsoft.json
         dotnet add package BouncyCastle
         dotnet build
         dotnet publish -c Release -r win10-x64
  
  - Zip the contents of bin\Release\<dotnetversion>\win10-x64\publish to a file called CertificateGenerator.zip
  - Update the CertificateGenerator.zip file at the following [location](https://github.com/microsoft/OMS-docker/blob/dilipr/winakslog/Kubernetes/windows/omsagentwindows/certgenerator)

### Configuration files

  These are checked in directly to the OMS-docker repo and have no dependencies on their linux counterparts in the Docker-Provider repo

### OMS output plugin
  
  This code comes from the Docker-Provider repo. The go plugin is shared between windows and linux.

- If any changes need to be made to the plugin code

  - Make the changes to the plugin [code](https://github.com/microsoft/Docker-Provider/tree/ci_feature/source/code/go/src/plugins)
  - Build the go plugin for windows on a windows build machine (Details to be provided later)
  - Check in the out_oms.so file at the following [location](https://github.com/microsoft/OMS-docker/tree/dilipr/winakslog/Kubernetes/windows/omsagentwindows)

### Ruby scripts
  
  These are duplicated from the Docker-Provider repo. Any change made there NEEDS to be replicated here.

### Powershell scripts

  These are checked in directly to the OMS-Docker repo. Edits can be made directly here.
