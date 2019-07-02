#
# ClassifyError.ps1
#
<# 
    .DESCRIPTION 
		Classifies the error type that a user is facing with their ACS-Engine Kubernetes or AKS-Engine cluster
 
    .PARAMETER SubscriptionId
        Subscription Id that the ACS-Engine Kubernetes or AKS-Engine cluster is in

    .PARAMETER ResourceGroupName
        Resource Group name where the ACS-Engine Kubernetes or AKS-Engine cluster is in
    
#>

param(
    [Parameter(mandatory = $true)]
    [string]$SubscriptionId,
    [Parameter(mandatory = $true)]
    [string]$ResourceGroupName	
)

$ErrorActionPreference = "Stop";
Start-Transcript -path .\TroubleshootDump.txt -Force
$OptOutLink = "https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers#uninstalling-the-chart"
$OptInLink = "https://github.com/helm/charts/tree/master/incubator/azuremonitor-containers#installing-the-chart"

# checks the required Powershell modules exist and if not exists, request the user permission to install
$azureRmProfileModule = Get-Module -ListAvailable -Name AzureRM.Profile 
$azureRmResourcesModule = Get-Module -ListAvailable -Name AzureRM.Resources 
$azureRmOperationalInsights = Get-Module -ListAvailable -Name AzureRM.OperationalInsights

if (($null -eq $azureRmProfileModule) -or ($null -eq $azureRmResourcesModule) -or ($null -eq $azureRmOperationalInsights)) {

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
            }
            catch {
                Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.profile in a new powershell window: eg. 'Install-Module AzureRM.profile -Repository PSGallery -Force'") -ForegroundColor Red
                exit
            }
            try {
                Write-Host("Installing AzureRM.Resources...")
                Install-Module AzureRM.Resources -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
            }
            catch {
                Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.Resoureces in a new powershell window: eg. 'Install-Module AzureRM.Resoureces -Repository PSGallery -Force'") -ForegroundColor Red 
                exit
            }
	
            try {
                Write-Host("Installing AzureRM.OperationalInsights...")
                Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
            }
            catch {
                Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.OperationalInsights in a new powershell window: eg. 'Install-Module AzureRM.OperationalInsights -Repository PSGallery -Force'") -ForegroundColor Red 
                exit
            }
        }
        1 {
            try {
                Import-Module AzureRM.profile -ErrorAction Stop
            }
            catch {
                Write-Host("Could not import AzureRM.profile...") -ForegroundColor Red
                Write-Host("Close other powershell logins and try installing the latest modules for AzureRM.profile in a new powershell window: eg. 'Install-Module AzureRM.profile -Repository PSGallery -Force'") -ForegroundColor Red
                Stop-Transcript
                exit
            }
            try {
                Import-Module AzureRM.Resources
            }
            catch {
                Write-Host("Could not import AzureRM.Resources... Please reinstall this Module") -ForegroundColor Red
                Stop-Transcript
                exit
            }
            try {
                Import-Module AzureRM.OperationalInsights
            }
            catch {
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
}
try {
    Write-Host("")
    Write-Host("Trying to get the current AzureRM login context...")
    $account = Get-AzureRmContext -ErrorAction Stop
    Write-Host("Successfully fetched current AzureRM context...") -ForegroundColor Green
    Write-Host("")
}
catch {
    Write-Host("")
    Write-Host("Could not fetch AzureRMContext..." ) -ForegroundColor Red
    Write-Host("")
}

#
#   Subscription existence and access check
#
if ($null -eq $account.Account) {
    try {
        Write-Host("Please login...")
        Login-AzureRmAccount -subscriptionid $SubscriptionId
    }
    catch {
        Write-Host("")
        Write-Host("Could not select subscription with ID : " + $SubscriptionId + ". Please make sure the SubscriptionId you entered is correct and you have access to the Subscription" ) -ForegroundColor Red
        Write-Host("")
        Stop-Transcript
        exit
    }
}
else {
    if ($account.Subscription.Id -eq $SubscriptionId) {
        Write-Host("Subscription: $SubscriptionId is already selected. Account details: ")
        $account
    }
    else {
        try {
            Write-Host("Current Subscription:")
            $account
            Write-Host("Changing to subscription: $SubscriptionId")
            Select-AzureRmSubscription -SubscriptionId $SubscriptionId
        }
        catch {
            Write-Host("")
            Write-Host("Could not select subscription with ID : " + $SubscriptionId + ". Please make sure the SubscriptionId you entered is correct and you have access to the Subscription" ) -ForegroundColor Red
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
    Write-Host("Could not find RG. Please make sure that the resource group name: '" + $ResourceGroupName + "'is correct and you have access to the Resource Group") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}
Write-Host("Successfully checked resource groups details...") -ForegroundColor Green

#
#  Validate the specified Resource Group has the AKS-Engine or ACS-Engine Kuberentes cluster resources 
#
Write-Host("Checking specified Resource Group has the AKS-Engine or ACS-Engine kubernetes cluster resources...")

$k8sMasterVMs = Get-AzureRmResource -ResourceType 'Microsoft.Compute/virtualMachines' -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -match "k8s-master" }

$isKubernetesCluster = $false 

foreach ($k8MasterVM in $k8sMasterVMs) {

    $tags = $k8MasterVM.Tags

    $aksEngineVersion = $tags['aksEngineVersion']  
    $orchestrator = $tags['orchestrator']   
    
    if ($null -eq $aksEngineVersion) {
        $acsEngineVersion = $tags['acsengineVersion']  
        Write-Host("Aks Engine version : " + $acsEngineVersion) -ForegroundColor Green  
    }
    else {
        Write-Host("Aks Engine version : " + $aksEngineVersion) -ForegroundColor Green  
    }

    Write-Host("orchestrator : " + $orchestrator) -ForegroundColor Green

    if ([string]$orchestrator.StartsWith('Kubernetes')) {
        $isKubernetesCluster = $true	
        if ($aksEngineVersion) {
            Write-Host("Resource group name: '" + $ResourceGroupName + "' found the AKS-Engine resources") -ForegroundColor Green
        }
        else {
            Write-Host("Resource group name: '" + $ResourceGroupName + "' found the ACS-Engine kubernetes resources") -ForegroundColor Green
        }

        break
    }
    else {
        Write-Host("This Resource group : '" + $ResourceGroupName + "'does not have the AKS-engine or ACS-Engine Kubernetes resources") -ForegroundColor Red
        exit 
    }
}

if ($isKubernetesCluster -eq $false) {
    Write-Host("Monitoring only supported  for AKS-Engine or ACS-Engine with Kubernetes") -ForegroundColor Red
    exit 
}

Write-Host("Successfully checked the AKS-Engine or ACS-Engine Kuberentes cluster resources in specified resource group") -ForegroundColor Green

#
#  Extract logAnalyticsWorkspaceResourceId and clusterName (if exists) tag(s) to the K8s master VMs
#

foreach ($k8MasterVM in $k8sMasterVMs) { 

    $r = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName  $k8MasterVM.Name
	
    if ($null -eq $r) {
        Write-Host("Get-AzureRmResource for Resource Group: " + $ResourceGroupName + "Resource Name :" + $k8MasterVM.Name + " failed" ) -ForegroundColor Red
        exit 
    }

    if ($null -eq $r.Tags) {
	   
        Write-Host("K8s master VM does not have required tags" ) -ForegroundColor Red
        Write-Host("Please try to opt out of monitoring and opt-in using the following links:") -ForegroundColor Red
        Write-Host("Opt-out - " + $OptOutLink) -ForegroundColor Red
        Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red		
        exit 
    }
    
    if ($r.Tags.ContainsKey("logAnalyticsWorkspaceResourceId")) {	   
        Write-host $r.Tags["logAnalyticsWorkspaceResourceId"]
        $LogAnalyticsWorkspaceResourceID = $r.Tags["logAnalyticsWorkspaceResourceId"]
        $LogAnalyticsWorkspaceResourceID = $LogAnalyticsWorkspaceResourceID.Trim()       
    }
    

    if ($r.Tags.ContainsKey("clusterName")) {	  
        $AksEngineClusterName = $r.Tags["clusterName"]
        $AksEngineClusterName = $AksEngineClusterName.Trim()     
    }
}


if ($null -eq $LogAnalyticsWorkspaceResourceID) {
    Write-Host("There is no existing logAnalyticsWorkspaceResourceId tag on AKS-Engine k8 master nodes so this indicates this cluster not enabled monitoring or tags have been removed" ) -ForegroundColor Red	
    Write-Host("Please try to opt-in for monitoring using the following links:") -ForegroundColor Red    
    Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red
    exit
}
else {

    if ($null -eq $AksEngineClusterName) {
        Write-Host("There is no existing clusterName tag on AKS-Engine k8 master nodes to correlate the clusterName used on the omsagent" ) -ForegroundColor Red	
        Write-Host("Please add the clusterName tag with the value of clusterName used during the omsagent agent onboarding. Refer below link for details:") -ForegroundColor Red    
        Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red

        exit
    }

    Write-Host("Configured LogAnalyticsWorkspaceResourceId: : '" + $LogAnalyticsWorkspaceResourceID + "' ") 
    $workspaceSubscriptionId = $LogAnalyticsWorkspaceResourceID.split("/")[2]
    $workspaceResourceGroupName = $LogAnalyticsWorkspaceResourceID.split("/")[4]
    $workspaceName = $LogAnalyticsWorkspaceResourceID.split("/")[8]

    try {
        if ($SubscriptionId -ne $workspaceSubscriptionId) {
            Write-Host("Changing to workspace's subscription")
            Select-AzureRmSubscription -SubscriptionId $workspaceSubscriptionId
        }
    }
    catch {
        Write-Host("")
        Write-Host("Could not change to Workspace subscriptionId : '" + $workspaceSubscriptionId + "'." ) -ForegroundColor Red
        Write-Host("")
        Stop-Transcript
        exit
    }


    #
    #   Check WS subscription exists and access
    #
    try {
        Write-Host("Checking workspace subscription details...") 
        Get-AzureRmSubscription -SubscriptionId $workspaceSubscriptionId -ErrorAction Stop
    }
    catch {
        Write-Host("")
        Write-Host("The subscription containing the workspace (" + $LogAnalyticsWorkspaceResourceID + ") looks like it was deleted or you do NOT have access to this workspace") -ForegroundColor Red
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
    Get-AzureRmResourceGroup -Name $workspaceResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
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
        $WorkspaceIPDetails = Get-AzureRmOperationalInsightsIntelligencePacks -ResourceGroupName $workspaceResourceGroupName -WorkspaceName $workspaceName -ErrorAction Stop
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

            $CurrentDir = (Get-Item -Path ".\" -Verbose).FullName
            $TemplateFile = $CurrentDir + "\ContainerInsightsSolution.json"
            $DeploymentName = "ContainerHealthOnboarding-Solution-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
            $Parameters = @{ }
            $Parameters.Add("workspaceResourceId", $LogAnalyticsWorkspaceResourceID)
            $Parameters.Add("workspaceRegion", $WorkspaceLocation)

            $Parameters

            try {
                New-AzureRmResourceGroupDeployment -Name $DeploymentName `
                    -ResourceGroupName $workspaceResourceGroupName `
                    -TemplateFile $TemplateFile `
                    -TemplateParameterObject $Parameters -ErrorAction Stop`
                Write-Host("")
                Write-Host("Template deployment was successful. You will be able to see data flowing into your cluster in 10-15 mins.") -ForegroundColor Green
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
}

Write-Host("")
Stop-Transcript
