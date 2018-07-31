#
# ClassifyError.ps1
#
<# 
    .DESCRIPTION 
		Classifies the error type that a user is facing with their AKS cluster
 
    .PARAMETER SubscriptionId
        Subscription Id that the AKS cluster is in

    .PARAMETER ResourceGroupName
        Resource Group name where the AKS cluster is in

    .PARAMETER AKSClusterName
        AKS Cluster name
#>

param(
	[Parameter(mandatory=$true)]
	[string]$SubscriptionId,
	[Parameter(mandatory=$true)]
	[string]$ResourceGroupName,
	[Parameter(mandatory=$true)]
	[string]$AKSClusterName
)

$ErrorActionPreference = "Stop";
Start-Transcript -path .\TroubleshootDump.txt -Force
$DocumentationLink = "https://github.com/Microsoft/OMS-docker/blob/troubleshooting_doc/Troubleshoot/README.md"
$OptOutLink = "https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#how-to-stop-monitoring-with-container-health"
$OptInLink = "https://docs.microsoft.com/en-us/azure/monitoring/monitoring-container-health#enable-container-health-monitoring-for-a-new-cluster"

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
			AzureRM.Resources, AzureRM.OperationalInsights and AzureRM.profile using the command`
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
	
		try {
			Write-Host("Installing AzureRM.OperationalInsights...")
			Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
		} catch {
			Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.OperationalInsights in a new powershell window: eg. 'Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force'") -ForegroundColor Red 
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
		try {
			Import-Module AzureRM.OperationalInsights
		} catch {
			Write-Host("Could not import AzureRM.OperationalInsights... Please reinstall this Module") -ForegroundColor Red
			Stop-Transcript
			exit
		}
		Write-Host("Running troubleshooting script... Please reinstall this Module")
		Write-Host("")
	}
	2 { 
		Write-Host("")
		Stop-Transcript
		exit
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

#
#   Subscription existance and access check
#
if ($account.Account -eq $null) {
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
	Write-Host("Could not find RG. Please make sure that the resource group name: '" + $ResourceGroupName + "'is correct and you have access to the cluster") -ForegroundColor Red
	Write-Host("")
	Stop-Transcript
	exit
}
Write-Host("Successfully checked resource groups details...") -ForegroundColor Green

Write-Host("Checking AKS Cluster details...")
try {
	$ResourceDetailsArray = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -Name $AKSClusterName -ExpandProperties -ErrorAction Stop -WarningAction Stop
} catch {
	Write-Host("")
	Write-Host("Could not fetch cluster details: Please make sure that the AKS Cluster name: '" + $AKSClusterName + "' is correct and you have access to the cluster") -ForegroundColor Red
	Write-Host("")
	Stop-Transcript
	exit
}

if ($ResourceDetailsArray -eq $null) {
	Write-Host("")
	Write-Host("Could not fetch cluster details: Please make sure that the AKS Cluster name: '" + $AKSClusterName + "' is correct and you have access to the cluster") -ForegroundColor Red
	Write-Host("")
	Stop-Transcript
	exit
} else {
	Write-Host("Successfully checked AKS Cluster details...") -ForegroundColor Green
	Write-Host("")
	foreach ($ResourceDetail in $ResourceDetailsArray) {
		if ($ResourceDetail.ResourceType -eq "Microsoft.ContainerService/managedClusters") {
			$LogAnalyticsWorkspaceResourceID = $ResourceDetail.Properties.addonProfiles.omsagent.config.logAnalyticsWorkspaceResourceID
			break
		}
	}
}

if ($LogAnalyticsWorkspaceResourceID -eq $null) {
	Write-Host("")
	Write-Host("No log analytics workspace associated with the cluster: Please see how to onboard your cluster to Container health from the following documentation: " + $OptInLink) -ForegroundColor Red
	Write-Host("")
	Stop-Transcript
	exit
} else {

	try {
		if($SubscriptionId -eq $LogAnalyticsWorkspaceResourceID.split("/")[2]) {
			#Nothing to do here
		} else {
			Write-Host("Changing to workspace's subscription")
			Select-AzureRmSubscription -SubscriptionId $LogAnalyticsWorkspaceResourceID.split("/")[2]
		}
	} catch {
		Write-Host("")
		Write-Host("Could not select subscription with ID : " + $SubscriptionId + ". Please make sure the ID you entered is correct and you have access to this workspace" ) -ForegroundColor Red
		Write-Host("")
		Stop-Transcript
		exit
	}


	#
	#   Check WS subscription exists and access
	#
	try {
		Write-Host("Checking workspace subscription details...") 
		Get-AzureRmSubscription -SubscriptionId $LogAnalyticsWorkspaceResourceID.split("/")[2] -ErrorAction Stop
	} catch {
		Write-Host("")
		Write-Host("The subscription containing the workspace (" + $LogAnalyticsWorkspaceResourceID +") looks like it was deleted or you do NOT have access to this workspace") -ForegroundColor Red
		Write-Host("Please try to opt out of monitoring and opt-in using the following links:") -ForegroundColor Red
		Write-Host("Opt-out - " + $OptOutLink) -ForegroundColor Red
		Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red
		Write-Host("")
		Stop-Transcript
		exit
	}
	Write-Host("Successfully fetched workspace subcription details...") -ForegroundColor Green
	Write-Host("")

	#
	#   Check WS Resourecegroup exists and access
	#
	Write-Host("Checking workspace's resource group details...")
	Get-AzureRmResourceGroup -Name $LogAnalyticsWorkspaceResourceID.split("/")[4] -ErrorVariable notPresent -ErrorAction SilentlyContinue
	if ($notPresent) {
		Write-Host("")
		Write-Host("Could not find resource group. Please make sure that the resource group name: '" + $ResourceGroupName + "'is correct and you have access to the workspace") -ForegroundColor Red
		Write-Host("Please try to opt out of monitoring and opt-in using the following links:") -ForegroundColor Red
		Write-Host("Opt-out - " + $OptOutLink) -ForegroundColor Red
		Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red
		Stop-Transcript
		exit
	}
	Write-Host("Successfully fetched workspace resource group...") -ForegroundColor Green
	Write-Host("")

	#
	#    Check WS exits and access
	#
	try {
		Write-Host("Checking workspace name's details...")
		$WorkspaceInformation = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $LogAnalyticsWorkspaceResourceID.split("/")[4] -Name $LogAnalyticsWorkspaceResourceID.split("/")[8] -ErrorAction Stop
		Write-Host("Successfully fetched workspace name...") -ForegroundColor Green
		Write-Host("")
	} catch {
		Write-Host("")
		Write-Host("Could not fetch details for the workspace : '" + $LogAnalyticsWorkspaceResourceID.split("/")[8] + "'. Please make sure that it hasn't been deleted and you have access to it.") -ForegroundColor Red
		Write-Host("Please try to opt out of monitoring and opt-in using the following links:") -ForegroundColor Red
		Write-Host("Opt-out - " + $OptOutLink) -ForegroundColor Red
		Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red
		Write-Host("")
		Stop-Transcript
		exit
	}
	
	$WorkspaceLocation = $WorkspaceInformation.Location
		
	if ($WorkspaceLocation -eq $null) {
			Write-Host("")
			Write-Host("Cannot fetch workspace location. Please try again...") -ForegroundColor Red
			Write-Host("")
			Stop-Transcript
			exit
	}

	try {
		$WorkspaceIPDetails = Get-AzureRmOperationalInsightsIntelligencePacks -ResourceGroupName $LogAnalyticsWorkspaceResourceID.split("/")[4] -WorkspaceName $LogAnalyticsWorkspaceResourceID.split("/")[8] -ErrorAction Stop
		Write-Host("Successfully fetched workspace IP details...") -ForegroundColor Green
		Write-Host("")
	} catch {
		Write-Host("")
		Write-Host("Failed to get the list of solutions onboarded to the workspace. Please make sure that it hasn't been deleted and you have access to it.") -ForegroundColor Red
		Write-Host("")
		Stop-Transcript
		exit
	}

	try {
		$ContainerInsightsIndex = $WorkspaceIPDetails.Name.IndexOf("ContainerInsights");
		Write-Host("Successfully located ContainerInsights solution") -ForegroundColor Green
		Write-Host("")
	} catch {
		Write-Host("Failed to get ContainerInsights solution details from the workspace") -ForegroundColor Red
		Write-Host("")
		Stop-Transcript
		exit
	}

	$isSolutionOnboarded = $WorkspaceIPDetails.Enabled[$ContainerInsightsIndex]
	
	if ($isSolutionOnboarded) {
		Write-Host("Everything looks good according to this script. Please contact us by emailing askcoin@microsoft.com for help") -ForegroundColor Green
	} else {
		#
		# Check contributor access to WS
		#
		$message = "Detected that there is a workspace associated with this cluster, but workspace - '" + $LogAnalyticsWorkspaceResourceID.split("/")[8] + "' in subscription '" +  $LogAnalyticsWorkspaceResourceID.split("/")[2] + "' IS NOT ONBOARDED with container health solution.";
		$question = " Do you want to onboard container health to the workspace?"

		$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
		$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
		$choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

		$decision = $Host.UI.PromptForChoice($message, $question, $choices, 0)

		if ($decision -eq 0) {
			Write-Host("Deploying template to onboard container health : Please wait...")

			$CurrentDir = (Get-Item -Path ".\" -Verbose).FullName
			$TemplateFile = $CurrentDir + "\ContainerInsightsSolution.json"
			$DeploymentName = "ContainerHealthOnboarding-Solution-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
			$Parameters = @{}
			$Parameters.Add("workspaceResourceId", $LogAnalyticsWorkspaceResourceID)
			$Parameters.Add("workspaceRegion", $WorkspaceLocation)

			$Parameters

			try {
				New-AzureRmResourceGroupDeployment -Name $DeploymentName `
											   -ResourceGroupName $LogAnalyticsWorkspaceResourceID.split("/")[4] `
											   -TemplateFile $TemplateFile `
											   -TemplateParameterObject $Parameters -ErrorAction Stop`
				Write-Host("")
				Write-Host("Template deployment was successful. You will be able to see data flowing into your cluster in 10-15 mins.") -ForegroundColor Green
				Write-Host("")
			} catch {
				Write-Host("Template deployment failed : Please contact us by emailing askcoin@microsoft.com for help") -ForegroundColor Red
			}
		} else {
			Write-Host("The container health solution isn't onboarded to your cluster. Please contact us by emailing askcoin@microsoft.com") -ForegroundColor Red
		}
	}
}

Write-Host("")
Stop-Transcript
