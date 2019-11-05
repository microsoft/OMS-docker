#
# ClassifyError.ps1
#
<#
    .DESCRIPTION
		 This troubleshooting script detects and fixes the issues related to onboarding of Azure Monitor for containers to k8s outside of the Azure

    .PARAMETER azureLogAnalyticsWorkspaceResourceId
        Id of the Azure Log Analytics Workspace
    .PARAMETER kubeConfig
        kubeconfig of the k8 cluster

     Pre-requisites:
      -  Contributor role permission on the Subscription of the Azure Arc Cluster
      -  kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/
      -  HELM https://github.com/helm/helm/releases
      -  Kubeconfig of the K8s cluster

#>

param(
    [Parameter(mandatory = $true)]
    [string]$azureLogAnalyticsWorkspaceResourceId,
    [Parameter(mandatory = $true)]
    [string]$kubeConfig
)

Write-Host("LogAnalyticsWorkspaceResourceId: : '" + $azureLogAnalyticsWorkspaceResourceId + "' ")
if (($azureLogAnalyticsWorkspaceResourceId.Contains("Microsoft.OperationalInsights/workspaces") -ne $true) -or ($azureLogAnalyticsWorkspaceResourceId.Split("/").Length -ne 9)) {
    Write-Host("Provided Azure Log Analytics resource id should be in this format /subscriptions/<subId>/resourceGroups/<rgName>/providers/Microsoft.OperationalInsights/workspaces/<workspaceName>") -ForegroundColor Red
    exit
}

if ([string]::IsNullOrEmpty($kubeConfig)) {
    Write-Host("kubeConfig should not be NULL or empty") -ForegroundColor Red
    exit
}

if ((Test-Path $kubeConfig -PathType Leaf) -ne $true) {
    Write-Host("provided kubeConfig path : '" + $kubeConfig + "' doesnt exist or you dont have read access") -ForegroundColor Red
    exit
}

# checks the required Powershell modules exist and if not exists, request the user permission to install
$azAccountModule = Get-Module -ListAvailable -Name Az.Accounts
$azResourcesModule = Get-Module -ListAvailable -Name Az.Resources
$azOperationalInsights = Get-Module -ListAvailable -Name Az.OperationalInsights

if (($null -eq $azAccountModule) -or ($null -eq $azResourcesModule) -or ($null -eq $azOperationalInsights)) {

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

                    Write-Host("Installing Az.OperationalInsights...")
                    Install-Module Az.OperationalInsights -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
                }
                catch {
                    Write-Host("Close other powershell logins and try installing the latest modules for Az.OperationalInsights in a new powershell window: eg. 'Install-Module Az.OperationalInsights -Repository PSGallery -Force'") -ForegroundColor Red
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

            if ($null -eq $azOperationalInsights) {
                try {
                    Import-Module Az.OperationalInsights -ErrorAction Stop
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

$workspaceSubscriptionId = $azureLogAnalyticsWorkspaceResourceId.split("/")[2]
# $workspaceResourceGroupName = $azureLogAnalyticsWorkspaceResourceId.split("/")[4]
# $workspaceName = $azureLogAnalyticsWorkspaceResourceId.split("/")[8]

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
            Set-AzContext -SubscriptionId $workspaceSubscriptionId
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

# validate configured log analytics workspace exists and got access permissions
Write-Host("Checking specified Azure Log Analytics Workspace exists and got access...")
$workspaceResource = Get-AzResource -ResourceId $azureLogAnalyticsWorkspaceResourceId
if ($null -eq $workspaceResource) {
    Write-Host("specified Azure Log Analytics resource id: " + $azureLogAnalyticsWorkspaceResourceId + ". either you dont have access or doesnt exist") -ForegroundColor Red
    exit
}

#
#    Check WS exits and access
#
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

$WorkspaceLocation = $WorkspaceInformation.Location
if ($null -eq $WorkspaceLocation) {
    Write-Host("")
    Write-Host("Cannot fetch workspace location. Please try again...") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}

$WorkspacePricingTier = $WorkspaceInformation.sku
Write-Host("Pricing tier of the configured LogAnalytics workspace: '" + $WorkspacePricingTier + "' ") -ForegroundColor Green

try {
    $WorkspaceIPDetails = Get-AzOperationalInsightsIntelligencePacks -ResourceGroupName $workspaceResourceGroupName -WorkspaceName $workspaceName -ErrorAction Stop
    Write-Host("Successfully fetched workspace IP details...") -ForegroundColor Green
    Write-Host("")
}
catch {
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
}
catch {
    Write-Host("Failed to get ContainerInsights solution details from the workspace") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}

$isSolutionOnboarded = $WorkspaceIPDetails.Enabled[$ContainerInsightsIndex]
if ($isSolutionOnboarded) {

    if ($WorkspacePricingTier -eq "Free") {
        Write-Host("Pricing tier of the configured LogAnalytics workspace is Free so you may need to upgrade to pricing tier to non-Free") -ForegroundColor Red
    }
    else {
        Write-Host("Everything looks good according to this script. Please contact us by emailing askcoin@microsoft.com for help") -ForegroundColor Green
    }
}
else {
    #
    # Check contributor access to WS
    #
    $message = "Detected that there is a workspace associated with this cluster, but workspace - '" + $workspaceName + "' in subscription '" + $workspaceSubscriptionId + "' IS NOT ONBOARDED with container health solution.";
    Write-Host($message)

    $question = " Do you want to onboard container health to the workspace?"

    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

    $decision = $Host.UI.PromptForChoice($message, $question, $choices, 0)

    if ($decision -eq 0) {
        Write-Host("Deploying template to onboard container health : Please wait...")
        $DeploymentName = "ContainerInsightsSolutionOnboarding-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
        $Parameters = @{ }
        $Parameters.Add("workspaceResourceId", $WorkspaceInformation.ResourceId)
        $Parameters.Add("workspaceRegion", $WorkspaceInformation.Location)
        $Parameters
        try {
            New-AzResourceGroupDeployment -Name $DeploymentName `
                -ResourceGroupName $defaultWorkspaceResourceGroup `
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
    }
    else {
        Write-Host("The container health solution isn't onboarded to your cluster. This required for the monitoring to work. Please contact us by emailing askcoin@microsoft.com if you need any help on this") -ForegroundColor Red
    }
}

Write-Host("set KUBECONFIG environment variable for the current session")
$Env:KUBECONFIG = $kubeConfig
Write-Host $Env:KUBECONFIG
Write-Host("Check whether the omsagent rs pod running correctly ...")

try {
    $rsPod = kubectl get rs -n kube-system -o json --selector='rsName=omsagent-rs' | ConvertFrom-Json
    if ($rsPod.Items.Length -ne 1) {
        Write-Host( "omsagent replicaset pod not scheduled or failed to scheduled. Please contact us by emailing askcoin@microsoft.com if you need any help on this")
        exit
    }

    $rsPodStatus = $rsPod.Items[0].status
    if ($rsPodStatus.availableReplicas -ne 1 ) {
        Write-Host( "omsagent availableReplicas count should be 1. Please contact us by emailing askcoin@microsoft.com if you need any help on this")
        exit
    }
    if ($rsPodStatus.fullyLabeledReplicas -ne 1 ) {
        Write-Host( "omsagent fullyLabeledReplicas count should be 1. Please contact us by emailing askcoin@microsoft.com if you need any help on this")
        exit
    }
    if ($rsPodStatus.readyReplicas -ne 1 ) {
        Write-Host( "omsagent fullyLabeledReplicas count should be 1. Please contact us by emailing askcoin@microsoft.com if you need any help on this")
        exit
    }
    if ($rsPodStatus.replicas -ne 1 ) {
        Write-Host( "omsagent replicas count should be 1. Please contact us by emailing askcoin@microsoft.com if you need any help on this")
        exit
    }

}
catch {
    Write-Host ("Failed to configure Tiller  : '" + $Error[0] + "' ") -ForegroundColor Red
    exit
}

