<#
    .DESCRIPTION

      Onboards the Kubernetes cluster hosted outside Azure to the Azure Monitor for containers.

      1. Creates the Azure log analytics workspace if doesn't exist in specified subscription
      2. Adds the ContainerInsights solution to the Azure log analytics workspace
      3. Outputs the Workspace Guid and Key which can be used to onboard the Agent

    .PARAMETER azureSubscriptionId
        Id of the Azure subscription where the Azure Log Analytics Workspace exists or can be created
    .PARAMETER workspaceResourceGroupName
        Name of the workspace RespourceGroup
   .PARAMETER workspaceName
        Name of the Azure Log Analytics workspace
   .PARAMETER workspaceLocation
        Location of the Azure Log Analytics workspace

#>
param(
    [Parameter(mandatory = $true)]
    [string]$azureSubscriptionId,
    [Parameter(mandatory = $true)]
    [string]$workspaceResourceGroupName,
    [Parameter(mandatory = $true)]
    [string]$workspaceName,
    [Parameter(mandatory = $true)]
    [string]$workspaceLocation
)

# checks the required Powershell modules exist and if not exists, request the user permission to install
$azAccountModule = Get-Module -ListAvailable -Name Az.Accounts
$azResourcesModule = Get-Module -ListAvailable -Name Az.Resources
$azOperationalInsights = Get-Module -ListAvailable -Name Az.OperationalInsights

if (($null -eq $azAccountModule) -or ($null -eq $azResourcesModule) -or ($null -eq $azOperationalInsights)) {

    $isWindowsMachine = $true
    if ($PSVersionTable -and $PSVersionTable.PSEdition -ccontains "core") {
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
            Write-Host("Please re-launch the script with elevated administrator") -ForegroundColor Red
            Stop-Transcript
            exit
        }
    }

    $message = "This script will try to install the latest versions of the following Modules : `
			    Az.Resources, Az.Accounts  and Az.OperationalInsights using the command`
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

            if ($null -eq $azOperationalInsights) {
                try {

                    Write-Host("Installing AzureRM.OperationalInsights...")
                    Install-Module Az.OperationalInsights -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
                }
                catch {
                    Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.OperationalInsights in a new powershell window: eg. 'Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force'") -ForegroundColor Red
                    exit
                }
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

            if ($null -eq $azAccountModule) {
                try {
                    Import-Module Az.OperationalInsights
                }
                catch {
                    Write-Host("Could not import Az.OperationalInsights... Please reinstall this Module") -ForegroundColor Red
                    Stop-Transcript
                    exit
                }
            }

        }
        2 {
            Write-Host("")
            Stop-Transcript
            exit
        }
    }
}

if ([string]::IsNullOrEmpty($workspaceResourceGroupName)) {
    Write-Host("workspaceResourceGroupName should not be NULL or empty") -ForegroundColor Red
    exit
}

if ([string]::IsNullOrEmpty($workspaceName)) {
    Write-Host("workspaceName should not be NULL or empty") -ForegroundColor Red
    exit
}

if ([string]::IsNullOrEmpty($workspaceLocation)) {
    Write-Host("workspaceLocation should not be NULL or empty") -ForegroundColor Red
    exit
}

Write-Host("LogAnalytics Workspace SubscriptionId : '" + $azureSubscriptionId + "' ") -ForegroundColor Green

try {
    Write-Host("")
    Write-Host("Trying to get the current Az login context...")
    $account = Get-AzContext -ErrorAction Stop
    Write-Host("Successfully fetched current AzContext context...") -ForegroundColor Green
    Write-Host("")
}
catch {
    Write-Host("")
    Write-Host("Could not fetch AzContext..." ) -ForegroundColor Red
    Write-Host("")
}


if ($null -eq $account.Account) {
    try {
        Write-Host("Please login...")
        Connect-AzAccount -subscriptionid $azureSubscriptionId
    }
    catch {
        Write-Host("")
        Write-Host("Could not select subscription with ID : " + $azureSubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
        Write-Host("")
        Stop-Transcript
        exit
    }
}
else {
    if ($account.Subscription.Id -eq $azureSubscriptionId) {
        Write-Host("Subscription: $SubscriptionId is already selected. Account details: ")
        $account
    }
    else {
        try {
            Write-Host("Current Subscription:")
            $account
            Write-Host("Changing to subscription: $azureSubscriptionId")
            Set-AzContext -SubscriptionId $azureSubscriptionId
        }
        catch {
            Write-Host("")
            Write-Host("Could not select subscription with ID : " + $azureSubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
            Write-Host("")
            Stop-Transcript
            exit
        }
    }
}

# validate specified logAnalytics workspace exists and got access permissions
Write-Host("Checking specified Log Analytics Resource Group exists and got access...")

$rg = Get-AzResourceGroup -ResourceGroupName $workspaceResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $rg) {
    Write-Host("Creating Resource Group: '" + $workspaceResourceGroupName + "' since this does not exist")
    New-AzResourceGroup -Name $workspaceResourceGroupName -Location $workspaceLocation
}
else {
    Write-Host("Resource Group : '" + $workspaceResourceGroupName + "' exists")
}

Write-Host("Checking specified Log Analytics Workspace exists and got access...")
$WorkspaceInformation = Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
if ($null -eq $WorkspaceInformation) {
    Write-Host("Creating Log Analytics Workspace: '" + $workspaceName + "'  in Resource Group: '" + $workspaceResourceGroupName + "' since this workspace does not exist")
    $WorkspaceInformation = New-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName -Location $workspaceLocation -ErrorAction Stop
}
else {
    Write-Host("Azure Log Workspace: '" + $workspaceName + "' exists in WorkspaceResourceGroup : '" + $workspaceResourceGroupName + "'  ")
}

Write-Host("Deploying template to onboard Container Insights solution : Please wait...")

$DeploymentName = "ContainerInsightsSolutionOnboarding-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
$Parameters = @{ }
$Parameters.Add("workspaceResourceId", $WorkspaceInformation.ResourceId)
$Parameters.Add("workspaceRegion", $WorkspaceInformation.Location)
$Parameters
try {
    New-AzResourceGroupDeployment -Name $DeploymentName `
        -ResourceGroupName $workspaceResourceGroupName `
        -TemplateUri  https://raw.githubusercontent.com/Microsoft/OMS-docker/ci_feature/docs/templates/azuremonitor-containerSolution.json `
        -TemplateParameterObject $Parameters -ErrorAction Stop`

    Write-Host("")
    Write-Host("Successfully added Container Insights Solution") -ForegroundColor Green

    Write-Host("")
}
catch {
    Write-Host ("Template deployment failed with an error: '" + $Error[0] + "' ") -ForegroundColor Red
    Write-Host("Please contact us by emailing askcoin@microsoft.com for help") -ForegroundColor Red
}

Write-Host("Retrieving WorkspaceGuid and Workspace Key of the Log Anaylytics workspace : '" + $WorkspaceInformation.Name + "'  ")

try {

    $WorkspaceSharedKeys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $WorkspaceInformation.ResourceGroupName -Name $WorkspaceInformation.Name -ErrorAction Stop -WarningAction SilentlyContinue
    Write-Host("Successfully retrieved WorkspaceGuid and Workspace Key of the Log Anaylytics workspace : '" + $WorkspaceInformation.Name + "'") -ForegroundColor Green
    Write-Host("Please use the following WorkspaceGuid and Key to onboard the Monitoring agent using Azure Monitor for containers HELM chart")
    Write-Host "Workspace Id:"$WorkspaceInformation.CustomerId
    Write-Host "Workspace Key:"$WorkspaceSharedKeys.PrimarySharedKey
}
catch {
    Write-Host ("Please validate whether you have Log Analytics Contributor role on the workspace error: '" + $Error[0] + "' ") -ForegroundColor Red
}









