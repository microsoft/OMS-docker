<# 
    .DESCRIPTION 
		Attach Log Analytics Workspace Resource Id tags to the master nodes or VMSS(es) in resource group of the AKS-Engine (or ACS-Engine Kubernetes) cluster
		        
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
 
    .PARAMETER SubscriptionId
        Subscription Id that the acs-engine Kubernetes cluster is in

    .PARAMETER ResourceGroupName
        Resource Group name where the acs-engine Kubernetes cluster is in

    .PARAMETER LogAnalyticsWorkspaceResourceId
        ResourceId of the Log Analytics. This should be the same as the one configured on the omsAgent of specified acs-engine Kubernetes cluster

	 .PARAMETER ClusterName
        Name of the cluster configured. This should be the same as the one configured on the omsAgent (for omsagent.env.clusterName) of specified acs-engine Kubernetes cluster	
#>

param(
	[Parameter(mandatory=$true)]
	[string]$SubscriptionId,
	[Parameter(mandatory=$true)]
	[string]$ResourceGroupName,
	[Parameter(mandatory=$true)]
	[string]$LogAnalyticsWorkspaceResourceId,
	[Parameter(mandatory=$true)]
	[string] $ClusterName
)


# checks the required Powershell modules exist and if not exists, request the user permission to install
$azureRmProfileModule = Get-Module -ListAvailable -Name AzureRM.Profile 
$azureRmResourcesModule = Get-Module -ListAvailable -Name AzureRM.Resources 

if (($null -eq $azureRmProfileModule) -or ($null -eq $azureRmResourcesModule)) {


    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	    Write-Host("Running script as an admin...")
	    Write-Host("")
    } else {
	    Write-Host("Please run the script as an administrator") -ForegroundColor Red
	    Stop-Transcript
	    exit
    }


    $message = "This script will try to install the latest versions of the following Modules : `
			    AzureRM.Resources and AzureRM.profile using the command`
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
			    Write-Host("Installing AzureRM.profile...")
			    Install-Module AzureRM.profile -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
		    } catch {
			    Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.profile in a new powershell window: eg. 'Install-Module AzureRM.profile -Repository PSGallery -Force'") -ForegroundColor Red
			    exit
		    }
		    try {
			    Write-Host("Installing AzureRM.Resources...")
			    Install-Module AzureRM.Resources -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
		    } catch {
			    Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.Resoureces in a new powershell window: eg. 'Install-Module AzureRM.Resoureces -Repository PSGallery -Force'") -ForegroundColor Red 
			    exit
		    }	
	
	    }
	    1 {
		    try {
			    Import-Module AzureRM.profile -ErrorAction Stop
		    } catch {
			    Write-Host("Could not import AzureRM.profile...") -ForegroundColor Red
			    Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.profile in a new powershell window: eg. 'Install-Module AzureRM.profile -Repository PSGallery -Force'") -ForegroundColor Red
			    Stop-Transcript
			    exit
		    }
		    try {
			    Import-Module AzureRM.Resources
		    } catch {
			    Write-Host("Could not import AzureRM.Resources... Please reinstall this Module") -ForegroundColor Red
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

try {
	Write-Host("")
	Write-Host("Trying to get the current AzureRM login context...")
	$account = Get-AzureRmContext -ErrorAction Stop
	Write-Host("Successfully fetched current AzureRM context...") -ForegroundColor Green
	Write-Host("")
} catch {
	Write-Host("")
	Write-Host("Could not fetch AzureRMContext..." ) -ForegroundColor Red
	Write-Host("")
}


if ($null -eq $account.Account) {
	try {
		Write-Host("Please login...")
		Login-AzureRmAccount -subscriptionid $SubscriptionId
	} catch {
		Write-Host("")
		Write-Host("Could not select subscription with ID : " + $SubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
		Write-Host("")
		Stop-Transcript
		exit
	}
} else {
	if ($account.Subscription.Id -eq $SubscriptionId) {
		Write-Host("Subscription: $SubscriptionId is already selected. Account details: ")
		$account
	} else {
		try {
			Write-Host("Current Subscription:")
			$account
			Write-Host("Changing to subscription: $SubscriptionId")
			Select-AzureRmSubscription -SubscriptionId $SubscriptionId
		} catch {
			Write-Host("")
			Write-Host("Could not select subscription with ID : " + $SubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
			Write-Host("")
			Stop-Transcript
			exit
		}
	}
}

#
#   Resource group existance and access check
#
Write-Host("Checking resource group details...")
Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent) {
	Write-Host("")
	Write-Host("Could not find RG. Please make sure that the resource group name: '" + $ResourceGroupName + "'is correct and you have access to the acs-engine cluster") -ForegroundColor Red
	Write-Host("")
	Stop-Transcript
	exit
}
Write-Host("Successfully checked resource groups details...") -ForegroundColor Green


$isKubernetesCluster = $false 

#
#  Validate the specified Resource Group has the acs-engine Kuberentes cluster resources (VMs or VMSSes)
#
$k8sMasterVMsOrVMSSes = Get-AzureRmResource -ResourceType 'Microsoft.Compute/virtualMachines' -ResourceGroupName $ResourceGroupName  | Where-Object {$_.Name -match "k8s-master"}

if($null -eq $k8sMasterVMsOrVMSSes) {

  $k8sMasterVMsOrVMSSes = Get-AzureRmResource -ResourceType 'Microsoft.Compute/virtualMachineScaleSets' -ResourceGroupName $ResourceGroupName  | Where-Object {$_.Name -match "k8s-master"}
}



foreach($k8MasterVM in $k8sMasterVMsOrVMSSes) {
  
  $tags = $k8MasterVM.Tags

  $acsEngineVersion = $tags['acsengineVersion']  

  if($null -eq $acsEngineVersion) {
     $acsEngineVersion = $tags['aksEngineVersion']  
  }

  $orchestrator = $tags['orchestrator']

  Write-Host("Aks-Engine or ACS-Engine version : " + $acsEngineVersion) -ForegroundColor Green

  Write-Host("orchestrator : " + $orchestrator) -ForegroundColor Green

  if([string]$orchestrator.StartsWith('Kubernetes')) {
   $isKubernetesCluster = $true

    Write-Host("Resource group name: '" + $ResourceGroupName + "' found the aks-engine Kubernetes resources") -ForegroundColor Green
  }
  else {
        Write-Host("Resource group name: '" + $ResourceGroupName + "'is doesnt have the Kubernetes aks-engine resources") -ForegroundColor Red
        exit 
  }

}

if($isKubernetesCluster -eq $false) {
    Write-Host("Resource group name: '" + $ResourceGroupName + "' doesnt have the Kubernetes acs-engine resources") -ForegroundColor Red
    exit 
}

# validate specified logAnalytics workspace exists or not

$workspaceResource = Get-AzureRmResource -ResourceId $LogAnalyticsWorkspaceResourceId

if($null -eq $workspaceResource) {
    Write-Host("Specified Log Analytics workspace ResourceId: '" + $LogAnalyticsWorkspaceResourceId + "' doesnt exist or don't have access to it") -ForegroundColor Red
    exit 
}

#
#  Add logAnalyticsWorkspaceResourceId and clusterName (if exists) tag(s) to the K8s master VMs
#

foreach($k8MasterVM in $k8sMasterVMsOrVMSSes) { 

        $r = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName  $k8MasterVM.Name
        
        if ($null -eq $r) {
           
           Write-Host("Get-AzureRmResource for Resource Group: " + $ResourceGroupName + "Resource Name :"  + $k8MasterVM.Name + " failed" ) -ForegroundColor Red
           exit 
        }

        if ($null -eq $r.Tags) {
           
           Write-Host("K8s master VM should have the tags" ) -ForegroundColor Red
           exit 
        }

        if($r.Tags.ContainsKey("logAnalyticsWorkspaceResourceId")) {
           
           $existingLogAnalyticsWorkspaceResourceId = $r.Tags["logAnalyticsWorkspaceResourceId"]
           
           if ($existingLogAnalyticsWorkspaceResourceId -eq $LogAnalyticsWorkspaceResourceId) {

               Write-Host("Ignoring the request since K8s master VM :" + $k8MasterVM.Name + " already has existing tag with specified logAnalyticsWorkspaceResourceId" ) -ForegroundColor Green
               exit
           }
                   
            Write-Host("K8s master VM :" + $k8MasterVM.Name + " has the existing tag for logAnalyticsWorkspaceResourceId with different workspace resource Id hence updating the resourceId with specified one" ) -ForegroundColor Green
            $r.Tags.Remove("logAnalyticsWorkspaceResourceId")          
                    
        }

        # if clusterName parameter passed-in
        if ($ClusterName) {
            if($r.Tags.ContainsKey("clusterName")) {
				$existingclusterName = $r.Tags["clusterName"]

				if ($existingclusterName -eq $ClusterName) {
					 Write-Host("Ignoring the request since K8s master VM :" + $k8MasterVM.Name + " already has existing tag with specified clusterName" ) -ForegroundColor Green
                     exit
				}
		
		      Write-Host("K8s master VM :" + $k8MasterVM.Name + " has the existing tag for clusterName with different from specified one" ) -ForegroundColor Green
              $r.Tags.Remove("clusterName")        
			}

           $r.Tags.Add("clusterName", $ClusterName) 
		}

        $r.Tags.Add("logAnalyticsWorkspaceResourceId", $LogAnalyticsWorkspaceResourceId) 
        Set-AzureRmResource -Tag $r.Tags -ResourceId $r.ResourceId -Force
  } 
if ($ClusterName) {
   Write-Host("Successfully added clusterName and logAnalyticsWorkspaceResourceId tag to K8s master VMs") -ForegroundColor Green 
}
else {
  Write-Host("Successfully added logAnalyticsWorkspaceResourceId tag to K8s master VMs") -ForegroundColor Green 
}


