<#
    .DESCRIPTION
		Attach Monitoring onboarding tags to the master nodes or VMSS(es) in resource group of the AKS-Engine (or ACS-Engine Kubernetes) cluster

        ---------------------------------------------------------------------------------------------------------
       | tagName                             | tagValue                                                         |
        ---------------------------------------------------------------------------------------------------------
       | logAnalyticsWorkspaceResourceId      | <azure ResourceId of the workspace configured on the omsAgent >  |
	   ----------------------------------------------------------------------------------------------------------
	   | clusterName                           | <name of the cluster configured during agent installation>       |
	   ----------------------------------------------------------------------------------------------------------

     https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags

	See below reference to get the Log Analytics workspace resource Id
	https://docs.microsoft.com/en-us/powershell/module/azurerm.operationalinsights/get-azurermoperationalinsightsworkspace?view=azurermps-6.11.0

	.PARAMETER NameoftheCloud
		Name of the cloud that the AKS-engine(or ACS-engine) Kubernetes cluster is in. Supported clouds are AzureCloud, AzureChinaCloud and AzureUSGovernment.

    .PARAMETER SubscriptionId
        Subscription Id that the aks-engine Kubernetes cluster is in

    .PARAMETER ResourceGroupName
        Resource Group name where the aks-engine Kubernetes cluster is in

    .PARAMETER LogAnalyticsWorkspaceResourceId
        Fully qualified ResourceId of the Log Analytics workspace. This should be the same as the one configured on the omsAgent of specified AKS-engine or (ACS-engine Kubernetes) cluster

	 .PARAMETER ClusterName
        Name of the cluster configured. This should be the same as the one configured on the omsAgent (for omsagent.env.clusterName) of specified ACS-engine Kubernetes cluster
#>

param(
    [Parameter(mandatory = $true)]
    [string]$NameoftheCloud,
    [Parameter(mandatory = $true)]
    [string]$SubscriptionId,
    [Parameter(mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(mandatory = $true)]
    [string]$LogAnalyticsWorkspaceResourceId,
    [Parameter(mandatory = $true)]
    [string] $ClusterName
)


# checks the required Powershell modules exist and if not exists, request the user permission to install
$azAccountModule = Get-Module -ListAvailable -Name Az.Accounts
$azResourcesModule = Get-Module -ListAvailable -Name Az.Resources
if (($null -eq $azAccountModule) -or ($null -eq $azResourcesModule)) {
    $isWindowsMachine = $true
    if ($PSVersionTable -and $PSVersionTable.PSEdition -contains "core") {
        if ($PSVersionTable.Platform -notcontains "win") {
            $isWindowsMachine = $false
        }
    }
    if ($isWindowsMachine) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host("Running script as an admin...")
            Write-Host("")
        }
        else {
            Write-Host("Please run the script as an administrator") -ForegroundColor Red
            Stop-Transcript
            exit
        }
    }

    $message = "This script will try to install the latest versions of the following Modules : `
			    Az.Resources and Az.Accounts using the command`
			    `'Install-Module {Insert Module Name} -Repository PSGallery -Force -AllowClobber -ErrorAction Stop -WarningAction Stop'
			    `If you do not have the latest version of these Modules, this troubleshooting script may not run."
    $question = "Do you want to Install the modules and run the script or just run the script?"

    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes, Install and run'))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Continue without installing the Module'))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Quit'))

    $decision = $Host.UI.PromptForChoice($message, $question, $choices, 0)

    switch ($decision) {
        0 {
            try {
                Write-Host("Installing Az.Resources...")
                Install-Module Az.Resources -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
            }
            catch {
                Write-Host("Close other powershell logins and try installing the latest modules for Az.Resources in a new powershell window: eg. 'Install-Module Az.Resources -Repository PSGallery -Force'") -ForegroundColor Red
                exit
            }
            try {
                Write-Host("Installing Az.Accounts...")
                Install-Module Az.Accounts -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
            }
            catch {
                Write-Host("Close other powershell logins and try installing the latest modules for Az.Accounts in a new powershell window: eg. 'Install-Module Az.Accounts -Repository PSGallery -Force'") -ForegroundColor Red
                exit
            }

        }
        1 {
            try {
                Import-Module Az.Resources -ErrorAction Stop
            }
            catch {
                Write-Host("Could not import Az.Resources ...") -ForegroundColor Red
                Write-Host("Close other powershell logins and try installing the latest modules for Az.Resources  in a new powershell window: eg. 'Install-Module Az.Resources  -Repository PSGallery -Force'") -ForegroundColor Red
                Stop-Transcript
                exit
            }
            try {
                Import-Module Az.Accounts
            }
            catch {
                Write-Host("Could not import Az.Accounts... Please reinstall this Module") -ForegroundColor Red
                Stop-Transcript
                exit
            }

        }
        2 {
            Write-Host("")
            Stop-Transcript
            exit
        }
    }
}

if ($NameoftheCloud -like "AzureCloud" -or
    $NameoftheCloud -like "AzureChinaCloud" -or
    $NameoftheCloud -like "AzureUSGovernment") {
    Write-Host("")
    Write-Host("Please login to $NameoftheCloud cloud environment with corresponding creds ...")
    Connect-AzAccount -Environment $NameoftheCloud -SubscriptionId $SubscriptionId
}
else {
    Write-Host("Error: Monitoring not supported in this cloud: $NameoftheCloud") -ForegroundColor Red
    exit
}

#
#   Resource group existance and access check
#
Write-Host("Checking resource group details...")
Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent) {
    Write-Host("")
    Write-Host("Could not find RG. Please make sure that the resource group name: '" + $ResourceGroupName + "'is correct and you have access to the aks-engine cluster") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}
Write-Host("Successfully checked resource groups details...") -ForegroundColor Green

$isKubernetesCluster = $false
#
#  Validate the specified Resource Group has the acs-engine Kuberentes cluster resources (VMs or VMSSes)
#
$k8sMasterVMsOrVMSSes = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines' -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -match "k8s-master" }
if ($null -eq $k8sMasterVMsOrVMSSes) {
    $k8sMasterVMsOrVMSSes = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachineScaleSets' -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -match "k8s-master" }
}

foreach ($k8MasterVM in $k8sMasterVMsOrVMSSes) {
    $tags = $k8MasterVM.Tags
    $acsEngineVersion = $tags['acsengineVersion']
    if ($null -eq $acsEngineVersion) {
        $acsEngineVersion = $tags['aksEngineVersion']
    }
    $orchestrator = $tags['orchestrator']
    Write-Host("Aks-Engine or ACS-Engine version : " + $acsEngineVersion) -ForegroundColor Green
    Write-Host("orchestrator : " + $orchestrator) -ForegroundColor Green
    if ([string]$orchestrator.StartsWith('Kubernetes')) {
        $isKubernetesCluster = $true
        Write-Host("Resource group name: '" + $ResourceGroupName + "' has the aks-engine resources") -ForegroundColor Green
    }
    else {
        Write-Host("Resource group name: '" + $ResourceGroupName + "'is doesnt have the aks-engine resources") -ForegroundColor Red
        exit
    }
}

if ($isKubernetesCluster -eq $false) {
    Write-Host("Resource group name: '" + $ResourceGroupName + "' doesnt have the aks-engine or acs-engine resources") -ForegroundColor Red
    exit
}

# validate specified logAnalytics workspace exists or not
$workspaceResource = Get-AzResource -ResourceId $LogAnalyticsWorkspaceResourceId
if ($null -eq $workspaceResource) {
    Write-Host("Specified Log Analytics workspace ResourceId: '" + $LogAnalyticsWorkspaceResourceId + "' doesnt exist or don't have access to it") -ForegroundColor Red
    exit
}

#
#  Add logAnalyticsWorkspaceResourceId and clusterName (if exists) tag(s) to the K8s master VMs
#
foreach ($k8MasterVM in $k8sMasterVMsOrVMSSes) {
    $r = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceName  $k8MasterVM.Name
    if ($null -eq $r) {
        Write-Host("Get-AzResource for Resource Group: " + $ResourceGroupName + "Resource Name :" + $k8MasterVM.Name + " failed" ) -ForegroundColor Red
        exit
    }
    if ($null -eq $r.Tags) {
        Write-Host("K8s master VM should have the tags" ) -ForegroundColor Red
        exit
    }
    if ($r.Tags.ContainsKey("logAnalyticsWorkspaceResourceId")) {
        $existingLogAnalyticsWorkspaceResourceId = $r.Tags["logAnalyticsWorkspaceResourceId"]
        if ($existingLogAnalyticsWorkspaceResourceId -eq $LogAnalyticsWorkspaceResourceId) {
            Write-Host("Ignoring attaching logAnalyticsWorkspaceResourceId tag to K8s master VM :" + $k8MasterVM.Name + " since it has already with same tag value" ) -ForegroundColor Yellow
        }
        else {
            Write-Host("K8s master VM :" + $k8MasterVM.Name + " has the existing tag for logAnalyticsWorkspaceResourceId with different workspace resource Id hence updating the resourceId with specified one" ) -ForegroundColor Green
            $r.Tags.Remove("logAnalyticsWorkspaceResourceId")
        }
    }

    # if clusterName parameter passed-in
    if ($ClusterName) {
        if ($r.Tags.ContainsKey("clusterName")) {
            $existingclusterName = $r.Tags["clusterName"]
            if ($existingclusterName -eq $ClusterName) {
                Write-Host("Ignoring attaching clusterName tag to K8s master VM :" + $k8MasterVM.Name + " since it has already with same tag value" ) -ForegroundColor Yellow
                exit
            }
            Write-Host("K8s master VM :" + $k8MasterVM.Name + " has the existing tag for clusterName with different from specified one" ) -ForegroundColor Green
            $r.Tags.Remove("clusterName")
        }
        $r.Tags.Add("clusterName", $ClusterName)
    }

    $r.Tags.Add("logAnalyticsWorkspaceResourceId", $LogAnalyticsWorkspaceResourceId)
    Set-AzResource -Tag $r.Tags -ResourceId $r.ResourceId -Force
}
if ($ClusterName) {
    Write-Host("Successfully added clusterName and logAnalyticsWorkspaceResourceId tag to K8s master VMs") -ForegroundColor Green
}
else {
    Write-Host("Successfully added logAnalyticsWorkspaceResourceId tag to K8s master VMs") -ForegroundColor Green
}

if ($NameoftheCloud -like "AzureCloud") {
    Write-Host("If you have already onboarded the azure monitor for containers HELM chart, proceed to https://aka.ms/azmon-containers to view the health and metrics of your cluster $clusterName") -ForegroundColor Green
}
elseif ($NameoftheCloud -like "AzureChinaCloud") {
    Write-Host("If you have already onboarded the azure monitor for containers HELM chart, proceed to https://aka.ms/azmon-containers to view the health and metrics of your cluster $clusterName") -ForegroundColor Green
}
else {
    Write-Host("If you have already onboarded the azure monitor for containers HELM chart, proceed to https://portal.azure.us to view the health and metrics of your cluster $clusterName") -ForegroundColor Green
}

