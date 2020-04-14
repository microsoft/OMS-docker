<#
    .DESCRIPTION

     Onboards Azure Monitor for containers to Azure Redhat Openshift v4 cluster

      1. Creates the Default Azure log analytics workspace if doesn't exist one in specified subscription
      2. Adds the ContainerInsights solution to the Azure log analytics workspace
      3. Adds the logAnalyticsWorkspaceResourceId tag on the provided Azure Redhat Openshift v4 cluster
      4. Installs Azure Monitor for containers HELM chart to the K8s cluster in Kubeconfig

    .PARAMETER azureAroV4ClusterResourceId
        Id of the Azure Redhat Openshift v4 Cluster
    .PARAMETER kubeContext
        kube-context of the k8 cluster to install Azure Monitor for containers HELM chart

     Pre-requisites:
      -  Azure Redhat Openshift v4 cluster Resource Id
      -  Contributor role permission on the Subscription of the Azure Redhat Openshift v4 cluster
      -  Helm v3.0.0 or higher  https://github.com/helm/helm/releases
      -  kube-context of the K8s cluster
 Note: 1. Please make sure you have all the pre-requisistes before running this script.

#>
param(
    [Parameter(mandatory = $true)]
    [string]$azureAroV4ClusterResourceId,
    [Parameter(mandatory = $true)]
    [string]$kubeContext
)

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

if ([string]::IsNullOrEmpty($azureAroV4ClusterResourceId)) {
    Write-Host("Specified Azure AROv4 ClusterResourceId should not be NULL or empty") -ForegroundColor Red
    exit
}

if (($azureAroV4ClusterResourceId.Contains("Microsoft.RedHatOpenShift/OpenShiftClusters") -ne $true) -or ($azureAroV4ClusterResourceId.Split("/").Length -ne 9)) {
    Write-Host("Provided cluster resource id should be in this format /subscriptions/<subId>/resourceGroups/<rgName>/providers/Microsoft.RedHatOpenShift/OpenShiftClusters/<clusterName>") -ForegroundColor Red
    exit
}

$resourceParts = $azureAroV4ClusterResourceId.Split("/")
$clusterSubscriptionId = $resourceParts[2]

Write-Host("Cluster SubscriptionId : '" + $clusterSubscriptionId + "' ") -ForegroundColor Green

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
        Connect-AzAccount -subscriptionid $clusterSubscriptionId
    }
    catch {
        Write-Host("")
        Write-Host("Could not select subscription with ID : " + $clusterSubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
        Write-Host("")
        Stop-Transcript
        exit
    }
}
else {
    if ($account.Subscription.Id -eq $clusterSubscriptionId) {
        Write-Host("Subscription: $SubscriptionId is already selected. Account details: ")
        $account
    }
    else {
        try {
            Write-Host("Current Subscription:")
            $account
            Write-Host("Changing to subscription: $clusterSubscriptionId")
            Set-AzContext -SubscriptionId $clusterSubscriptionId
        }
        catch {
            Write-Host("")
            Write-Host("Could not select subscription with ID : " + $clusterSubscriptionId + ". Please make sure the ID you entered is correct and you have access to the cluster" ) -ForegroundColor Red
            Write-Host("")
            Stop-Transcript
            exit
        }
    }
}

# validate specified AROv4 cluster exists and got access permissions
Write-Host("Checking specified Azure Redhat Openshift v4 cluster exists and got access...")
$clusterResource = Get-AzResource -ResourceId $azureAroV4ClusterResourceId
if ($null -eq $clusterResource) {
    Write-Host("specified Azure Redhat Openshift v4 cluster resource id either you dont have access or doesnt exist") -ForegroundColor Red
    exit
}
$clusterRegion = $clusterResource.Location

# mapping fors for default Azure Log Analytics workspace
$AzureCloudLocationToOmsRegionCodeMap = @{
    "australiasoutheast" = "ASE" ;
    "australiaeast"      = "EAU" ;
    "australiacentral"   = "CAU" ;
    "canadacentral"      = "CCA" ;
    "centralindia"       = "CIN" ;
    "centralus"          = "CUS" ;
    "eastasia"           = "EA" ;
    "eastus"             = "EUS" ;
    "eastus2"            = "EUS2" ;
    "eastus2euap"        = "EAP" ;
    "francecentral"      = "PAR" ;
    "japaneast"          = "EJP" ;
    "koreacentral"       = "SE" ;
    "northeurope"        = "NEU" ;
    "southcentralus"     = "SCUS" ;
    "southeastasia"      = "SEA" ;
    "uksouth"            = "SUK" ;
    "usgovvirginia"      = "USGV" ;
    "westcentralus"      = "EUS" ;
    "westeurope"         = "WEU" ;
    "westus"             = "WUS" ;
    "westus2"            = "WUS2"
}
$AzureCloudRegionToOmsRegionMap = @{
    "australiacentral"   = "australiacentral" ;
    "australiacentral2"  = "australiacentral" ;
    "australiaeast"      = "australiaeast" ;
    "australiasoutheast" = "australiasoutheast" ;
    "brazilsouth"        = "southcentralus" ;
    "canadacentral"      = "canadacentral" ;
    "canadaeast"         = "canadacentral" ;
    "centralus"          = "centralus" ;
    "centralindia"       = "centralindia" ;
    "eastasia"           = "eastasia" ;
    "eastus"             = "eastus" ;
    "eastus2"            = "eastus2" ;
    "francecentral"      = "francecentral" ;
    "francesouth"        = "francecentral" ;
    "japaneast"          = "japaneast" ;
    "japanwest"          = "japaneast" ;
    "koreacentral"       = "koreacentral" ;
    "koreasouth"         = "koreacentral" ;
    "northcentralus"     = "eastus" ;
    "northeurope"        = "northeurope" ;
    "southafricanorth"   = "westeurope" ;
    "southafricawest"    = "westeurope" ;
    "southcentralus"     = "southcentralus" ;
    "southeastasia"      = "southeastasia" ;
    "southindia"         = "centralindia" ;
    "uksouth"            = "uksouth" ;
    "ukwest"             = "uksouth" ;
    "westcentralus"      = "eastus" ;
    "westeurope"         = "westeurope" ;
    "westindia"          = "centralindia" ;
    "westus"             = "westus" ;
    "westus2"            = "westus2"
}

$workspaceRegionCode = "EUS"
$workspaceRegion = "eastus"
if ($AzureCloudRegionToOmsRegionMap.Contains($clusterRegion)) {
    $workspaceRegion = $AzureCloudRegionToOmsRegionMap[$clusterRegion]

    if ($AzureCloudLocationToOmsRegionCodeMap.Contains($workspaceRegion)) {
        $workspaceRegionCode = $AzureCloudLocationToOmsRegionCodeMap[$workspaceRegion]
    }
}

$defaultWorkspaceResourceGroup = "DefaultResourceGroup-" + $workspaceRegionCode
$defaultWorkspaceName = "DefaultWorkspace-" + $clusterSubscriptionId + "-" + $workspaceRegionCode

# validate specified logAnalytics workspace exists and got access permissions
Write-Host("Checking default Log Analytics Workspace Resource Group exists and got access...")
$rg = Get-AzResourceGroup -ResourceGroupName $defaultWorkspaceResourceGroup -ErrorAction SilentlyContinue
if ($null -eq $rg) {
    Write-Host("Creating Default Workspace Resource Group: '" + $defaultWorkspaceResourceGroup + "' since this does not exist")
    New-AzResourceGroup -Name $defaultWorkspaceResourceGroup -Location $workspaceRegion -ErrorAction Stop
}
else {
    Write-Host("Resource Group : '" + $defaultWorkspaceResourceGroup + "' exists")
}


Write-Host("Checking default Log Analytics Workspace exists and got access...")
$WorkspaceInformation = Get-AzOperationalInsightsWorkspace -ResourceGroupName $defaultWorkspaceResourceGroup -Name $defaultWorkspaceName -ErrorAction SilentlyContinue
if ($null -eq $WorkspaceInformation) {
    Write-Host("Creating Log Analytics Workspace: '" + $defaultWorkspaceName + "'  in Resource Group: '" + $defaultWorkspaceResourceGroup + "' since this workspace does not exist")
    $WorkspaceInformation = New-AzOperationalInsightsWorkspace -ResourceGroupName $defaultWorkspaceResourceGroup -Name $defaultWorkspaceName -Location $workspaceRegion -ErrorAction Stop
}
else {
    Write-Host("Azure Log Workspace: '" + $defaultWorkspaceName + "' exists in WorkspaceResourceGroup : '" + $defaultWorkspaceResourceGroup + "'  ")
}

Write-Host("Deploying template to onboard Container Insights solution : Please wait...")

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


Write-Host("Attaching logAnalyticsWorkspaceResourceId tag on the cluster ResourceId")
$clusterResource.Tags["logAnalyticsWorkspaceResourceId"] = $WorkspaceInformation.ResourceId
Set-AzResource -Tag $clusterResource.Tags -ResourceId $clusterResource.ResourceId -Force

$workspaceGUID = "";
$workspacePrimarySharedKey = "";
Write-Host("Retrieving WorkspaceGUID and WorkspacePrimaryKey of the workspace : " + $WorkspaceInformation.Name)
try {

    $WorkspaceSharedKeys = Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $WorkspaceInformation.ResourceGroupName -Name $WorkspaceInformation.Name -ErrorAction Stop -WarningAction SilentlyContinue
    $workspaceGUID = $WorkspaceInformation.CustomerId
    $workspacePrimarySharedKey = $WorkspaceSharedKeys.PrimarySharedKey
}
catch {
    Write-Host ("Failed to workspace details. Please validate whether you have Log Analytics Contributor role on the workspace error: '" + $Error[0] + "' ") -ForegroundColor Red
    exit
}

$helmVersion = helm version
Write-Host "Helm version" : $helmVersion

Write-Host("Adding incubator repo to helm: https://kubernetes-charts-incubator.storage.googleapis.com/")
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/

Write-Host("updating helm repo to get latest version of charts")
helm repo update

Write-Host("Installing Azure Monitor for containers HELM chart ...")
try {

    helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
    helm repo update
    $helmParameters = "omsagent.secret.wsid=$workspaceGUID,omsagent.secret.key=$workspacePrimarySharedKey,omsagent.env.clusterId=$azureAroV4ClusterResourceId"
    helm install azmon-containers-release-1 --set $helmParameters incubator/azuremonitor-containers --kube-context $kubeContext
}
catch {
    Write-Host ("Failed to Install Azure Monitor for containers HELM chart : '" + $Error[0] + "' ") -ForegroundColor Red
}

Write-Host("Proceed to https://aka.ms/azmon-containers to view your newly onboarded Azure Redhat Openshift v4 cluster") -ForegroundColor Green




