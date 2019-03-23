<# 
    .DESCRIPTION 
	   
       Creates the Managed Resource Group with required metadata as tags in Azure Public Cloud to reprents the Kubernetes cluster hosted outside the Azure Public Cloud.

       The name of the Managed Resource Group is same clusterName and resource group created in same subscription as Azure Log Analytics Workspace and location of the RG is same as workspace.


        Following tags are attached to Managed Resource Group   
                      
        ---------------------------------------------------------------------------------------------------------------------------------------------
       | tagName                             | tagValue                                                                                              | 
        ---------------------------------------------------------------------------------------------------------------------------------------------
       |clusterName                          | <name of the kubernetes clusterName. This should be same as configured on the omsagent>               |
       ----------------------------------------------------------------------------------------------------------------------------------------------
       |loganalyticsWorkspaceResourceId      | <azure resource Id of the log analytics workspace. This should be same as configued on the oms agent> |
       ----------------------------------------------------------------------------------------------------------------------------------------------       
       |hosteEnvironment                     | AzureStack or AWS or AME or etc                                                                       |      
       ----------------------------------------------------------------------------------------------------------------------------------------------
       |clusterType                          | AKS-Engine or ACS-Engine or AKS or Kubernetes. Default is AKS-Engine.                                                         |
       ----------------------------------------------------------------------------------------------------------------------------------------------
       |creationsource                       | azuremonitorforcontainers.                                                                             |
       ----------------------------------------------------------------------------------------------------------------------------------------------   
       |orchestrator                         | kubernetes. This is only supported orchestrator.                                                                                            |       
       ----------------------------------------------------------------------------------------------------------------------------------------------

     
     https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags  
	 
	See below reference to get the Log Analytics workspace resource Id 
	https://docs.microsoft.com/en-us/powershell/module/azurerm.operationalinsights/get-azurermoperationalinsightsworkspace?view=azurermps-6.11.0
 
    .PARAMETER custerName
        Name of the cluster configured on the OMSAgent

    .PARAMETER loganalyticsWorkspaceResourceId
        Azure ResourceId of the log analytics workspace Id
   
#>

param(
    [Parameter(mandatory = $true)]
    [string]$clusterName,
    [Parameter(mandatory = $true)]
    [string]$LogAnalyticsWorkspaceResourceId,
    [Parameter(mandatory = $true)]
    [string]$hosteEnvironment,
    [Parameter(mandatory = $true)]
    [string]$clusterType = "AKS-Engine"

)


# checks the required Powershell modules exist and if not exists, request the user permission to install
$azAccountModule = Get-Module -ListAvailable -Name Az.Accounts
$azResourcesModule = Get-Module -ListAvailable -Name Az.Resources
$azureRmOperationalInsights = Get-Module -ListAvailable -Name AzureRM.OperationalInsights

if (($null -eq $azAccountModule) -or ($null -eq $azResourcesModule) -or ($null -eq $azureRmOperationalInsights)) {


    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host("Running script as an admin...")
        Write-Host("")
    }
    else {
        Write-Host("Please execute the script as an administrator") -ForegroundColor Red
        Stop-Transcript
        exit
    }


    $message = "This script will try to install the latest versions of the following Modules : `
			    Az.Resources and Az.Accounts  using the command`
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

            if ($null -eq $azResourcesModule) {
                try {
                    Write-Host("Installing Az.Resources...")
                    Install-Module Az.Resources -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
                }
                catch {
                    Write-Host("Close other powershell logins and try installing the latest modules forAz.Accounts in a new powershell window: eg. 'Install-Module Az.Accounts -Repository PSGallery -Force'") -ForegroundColor Red
                    exit
                }
            }

            if ($null -eq $azAccountModule) {
                try {
                    Write-Host("Installing Az.Accounts...")
                    Install-Module Az.Accounts -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
                }
                catch {
                    Write-Host("Close other powershell logins and try installing the latest modules forAz.Accounts in a new powershell window: eg. 'Install-Module Az.Accounts -Repository PSGallery -Force'") -ForegroundColor Red
                    exit
                }
            }

            try {
                if ($null -eq $azureRmOperationalInsights) {
                    Write-Host("Installing AzureRM.OperationalInsights...")
                    Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
                }
            }
            catch {
                Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.OperationalInsights in a new powershell window: eg. 'Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force'") -ForegroundColor Red 
                exit
            }
          
           
        }
        1 {

            if ($null -eq $azResourcesModule) {
                try {
                    Import-Module Az.Resources -ErrorAction Stop
                }
                catch {
                    Write-Host("Could not import Az.Resources...") -ForegroundColor Red
                    Write-Host("Close other powershell logins and try installing the latest modules for Az.Resources in a new powershell window: eg. 'Install-Module Az.Resources -Repository PSGallery -Force'") -ForegroundColor Red
                    Stop-Transcript
                    exit
                }
            }
            if ($null -eq $azAccountModule) {
                try {
                    Import-Module Az.Accounts -ErrorAction Stop
                }
                catch {
                    Write-Host("Could not import Az.Accounts...") -ForegroundColor Red
                    Write-Host("Close other powershell logins and try installing the latest modules for Az.Accounts in a new powershell window: eg. 'Install-Module Az.Accounts -Repository PSGallery -Force'") -ForegroundColor Red
                    Stop-Transcript
                    exit
                }
            } 
            
            try {
                Import-Module AzureRM.OperationalInsights
            }
            catch {
                Write-Host("Could not import AzureRM.OperationalInsights... Please reinstall this Module") -ForegroundColor Red
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


if ([string]::IsNullOrEmpty($LogAnalyticsWorkspaceResourceId)) { 
   
    Write-Host("LogAnalyticsWorkspaceResourceId shouldnot be NULL or empty") -ForegroundColor Red
    exit
}


$workspaceResourceDetails = $LogAnalyticsWorkspaceResourceId.Split("/")

if ($workspaceResourceDetails.Length -ne 9) { 

    Write-Host("LogAnalyticsWorkspaceResourceId should be valid Azure Resource Id format") -ForegroundColor Red

    exit

}


$workspaceSubscriptionId = $workspaceResourceDetails[2]

$workspaceSubscriptionId = $workspaceSubscriptionId.Trim()

Write-Host("LogAnalytics Workspace SubscriptionId : '" + $workspaceSubscriptionId + "' ") -ForegroundColor Green

try {
    Write-Host("")
    Write-Host("Trying to get the current Az login context...")
    $account = Get-AzContext -ErrorAction Stop
    Write-Host("Successfully fetched current AzContext context...") -ForegroundColor Green
    Write-Host("")
}
catch {
    Write-Host("")
    Write-Host("Could not fetch AzContext..." ) -ForegroundColor Yellow
    Write-Host("")
}


if ($account.Account -eq $null) {
    try {
        Write-Host("Please login...")
        Connect-AzAccount -subscriptionid $workspaceSubscriptionId
    }
    catch {
        Write-Host("")
        Write-Host("Could not select subscription with ID : " + $workspaceSubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
        Write-Host("")
        Stop-Transcript
        exit
    }
}


if ($account.Account -eq $null) {
    try {
        Write-Host("Please login...")
        Login-AzureRmAccount -subscriptionid $workspaceSubscriptionId
    }
    catch {
        Write-Host("")
        Write-Host("Could not select subscription with ID : " + $SubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
        Write-Host("")
        Stop-Transcript
        exit
    }
}
else {
    if ($account.Subscription.Id -eq $workspaceSubscriptionId) {
        Write-Host("Subscription: $workspaceSubscriptionId is already selected. Account details: ")
        $account
    }
    else {
        try {
            Write-Host("Current Subscription:")
            $account
            Write-Host("Changing to subscription: $workspaceSubscriptionId")
            Select-AzureRmSubscription -SubscriptionId $workspaceSubscriptionId
        }
        catch {
            Write-Host("")
            Write-Host("Could not select subscription with ID : " + $workspaceSubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
            Write-Host("")
            Stop-Transcript
            exit
        }
    }
}


# validate specified logAnalytics workspace exists or not
Write-Host("Checking specified LogAnalyticsWorkspaceResourceId exists and got access...")

try {
    Write-Host("Checking workspace name's details...")
    $WorkspaceInformation = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName -ErrorAction Stop
    Write-Host("Successfully fetched workspace name...") -ForegroundColor Green
    Write-Host("")
}
catch {
    Write-Host("")
    Write-Host("Could not fetch details for the workspace : '" + $workspaceName + "'. Please make sure that it hasn't been deleted and you have access to it.") -ForegroundColor Red
    Write-Host("Please try to opt out of monitoring and opt-in using the following links:") -ForegroundColor Red
    Write-Host("Opt-out - " + $OptOutLink) -ForegroundColor Red
    Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}

$workspaceResource = Get-AzureRmResource -ResourceId $LogAnalyticsWorkspaceResourceId

if ($workspaceResource -eq $null) {
    Write-Host("Specified Log Analytics workspace ResourceId: '" + $LogAnalyticsWorkspaceResourceId + "' doesnt exist or don't have access to it") -ForegroundColor Red
    exit 
}

$workspaceResourceLocation = $workspaceResource.Location.ToString()

Write-Host("Log Analytics WorkspaceResource Location  : '" + $workspaceResourceLocation + "' ")

Write-Host("Successfully verified specified LogAnalyticsWorkspaceResourceId exist...")


#
#   Check if there is already Resource group exists with the name of the clusterName 
#

$managedResourceGroup = $clusterName

Write-Host("Creating managed resource group ...")

Get-AzureRmResourceGroup -Name $managedResourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent) {

    Write-Host("creating resource group: '" + $managedResourceGroup + "' + in location : '" + $workspaceResource.Location + "' + ")

    New-AzureRmResourceGroup -Name $clusterName -Location $workspaceResourceLocation


}
else { 

    # Figure out if we need to make unique appending Guid or hash etc.

    Write-Host("There is already RG with this name. Hence appending  _azuremonitor to the cluster name to make distinct") -ForegroundColor Green

    $managedResourceGroup = $clusterName + "_azuremonitor"

    Write-Host("creating managed resource group: '" + $managedResourceGroup + "' + in location : '" + $workspaceResource.Location + "' + ")

    New-AzureRmResourceGroup -Name $managedResourceGroup -Location $workspaceResourceLocation

    Write-Host("successfully created managed resource group: '" + $managedResourceGroup + "' + in location : '" + $workspaceResource.Location + "' + ")

}

Write-Host("Successfully created managed resource groups ...") -ForegroundColor Green


# attach tags to the managed resource group

Write-Host("Attaching required tags to managed resource group: '" + $managedResourceGroup + "' ...")

$r = Get-AzureRmResourceGroup -ResourceGroupName $managedResourceGroup 

$monitoringTags = @{ }


$monitoringTags.Add("clusterName", $clusterName)
$monitoringTags.Add("logAnalyticsWorkspaceResourceId", $LogAnalyticsWorkspaceResourceId)
$monitoringTags.Add("hosteEnvironment", $hosteEnvironment)
$monitoringTags.Add("clusterType", $clusterType)


$monitoringTags.Add("creationsource", "azuremonitorforcontainers")
$monitoringTags.Add("orchestrator", "kubernetes")
  

Set-AzureRmResource -Tag $monitoringTags -ResourceId $r.ResourceId -Force

Write-Host("Successfully attached required tags to managed resource group: '" + $managedResourceGroup + "' ...")


# locking the managed resource group to prevent accidental deletion or modifcation

# locking the managed resource group

Write-Host("Locking managed resource group: '" + $managedResourceGroup + "' to avoid accidental deletion...")


New-AzureResourceLock -LockLevel CanNotDelete -LockName azuremonitorforcontainers -ResourceGroupName $managedResourceGroup -ErrorVariable lockError

if ($lockError) {

}
else {

    Write-Host("Successfully locked resource group: '" + $managedResourceGroup + "' to avoid accidental deletion...") 
}











