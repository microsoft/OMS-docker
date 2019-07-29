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
    [Parameter(mandatory = $true)]
    [string]$SubscriptionId,
    [Parameter(mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(mandatory = $true)]
    [string]$AKSClusterName
)

$ErrorActionPreference = "Stop";
Start-Transcript -path .\TroubleshootDump.txt -Force
$OptOutLink = "https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-optout"
$OptInLink = "https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-onboard"
$MonitoringMetricsRoleDefinitionName = "Monitoring Metrics Publisher"

$MdmCustomMetricAvailabilityLocations = (
    'eastus',
    'southcentralus',
    'westcentralus',
    'westus2',
    'southeastasia',
    'northeurope',
    'westeurope'
);

try {
    Write-Host("")
    Write-Host("Trying to get the current Az login context...")
    $account = Get-AzContext -ErrorAction Stop
    Write-Host("Successfully fetched current Az context...") -ForegroundColor Green
    Write-Host("")
}
catch {
    Write-Host("")
    Write-Host("Could not fetch AzContext..." ) -ForegroundColor Red
    Write-Host("")
}

#
#   Subscription existance and access check
#
if ($null -eq $account.Account) {
    try {
        Write-Host("Please login...")
        Login-AzAccount -subscriptionid $SubscriptionId
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
            Select-AzSubscription -SubscriptionId $SubscriptionId
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
Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent) {
    Write-Host("")
    Write-Host("Could not find RG. Please make sure that the resource group name: '" + $ResourceGroupName + "'is correct and you have access to the Resource Group") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}
Write-Host("Successfully checked resource groups details...") -ForegroundColor Green

Write-Host("Checking AKS Cluster details...")
try {
    $ResourceDetailsArray = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $AKSClusterName -ResourceType "Microsoft.ContainerService/managedClusters" -ExpandProperties -ErrorAction Stop -WarningAction Stop
}
catch {
    Write-Host("")
    Write-Host("Could not fetch cluster details: Please make sure that the AKS Cluster name: '" + $AKSClusterName + "' is correct and you have access to the cluster") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}

if ($null -eq $ResourceDetailsArray) {
    Write-Host("")
    Write-Host("Could not fetch cluster details: Please make sure that the AKS Cluster name: '" + $AKSClusterName + "' is correct and you have access to the cluster") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}
else {
    Write-Host("Successfully checked AKS Cluster details...") -ForegroundColor Green
    Write-Host("")
    foreach ($ResourceDetail in $ResourceDetailsArray) {
        if ($ResourceDetail.ResourceType -eq "Microsoft.ContainerService/managedClusters") {
            #gangams: profile can be different casing so convert properties to lowecase and extract it
            $props = ($ResourceDetail.Properties | ConvertTo-Json).toLower() | ConvertFrom-Json;

            if ($null -eq $props.addonprofiles.omsagent.config) {
                Write-Host("Your cluster isn't onboarded to Azure monitor for containers. Please refer to the following documentation to onboard:") -ForegroundColor Red;
                Write-Host($OptInLink) -ForegroundColor Red;
                Write-Host("");
                Stop-Transcript
                exit
            }

            $omsagentconfig = $props.addonprofiles.omsagent.config;
            
            #gangams - figure out betterway to do this
            $omsagentconfig = $omsagentconfig.Trim("{", "}");
            $LogAnalyticsWorkspaceResourceID = $omsagentconfig.split("=")[1];
            $AKSClusterResourceId = $ResourceDetail.ResourceId
			
            Write-Host("AKS Cluster ResourceId: '" + $AKSClusterResourceId + "' ");  
			
            break
        }
    }
}


Write-Host("Currently checking if the cluster is onboarded to custom metrics for Azure monitor for containers...");

#Pre requisite - need cluster spn object Id
try {
    $clusterDetails = Get-AzAks -Id $AKSClusterResourceId -ErrorVariable clusterFetchError -ErrorAction SilentlyContinue;
    Write-Host($clusterDetails | Format-List | Out-String);
    $clusterSPNClientID = $clusterDetails.ServicePrincipalProfile.ClientId;
    $clusterLocation = $clusterDetails.Location;

    if ($MdmCustomMetricAvailabilityLocations -contains $clusterLocation) {
        Write-Host('Cluster is in a location where Custom metrics are available') -ForegroundColor Green;
        if ($null -eq $clusterSPNClientID ) {
            Write-Host("There is no service principal associated with this cluster.") -ForegroundColor Red;
            Write-Host("");
        }
        else {
            # Convert the client ID to the Object ID
            $clusterSPN = Get-AzADServicePrincipal -ServicePrincipalName $clusterSPNClientID;
            $clusterSPNObjectID = $clusterSPN.Id;
            if ($null -eq $clusterSPNObjectID) {
                Write-Host("Couldn't convert Client ID to Object ID.") -ForegroundColor Red;
                Write-Host("Please contact us by emailing askcoin@microsoft.com for help") -ForegroundColor Red;
                Write-Host("");
            }

            $MonitoringMetricsPublisherCandidates = Get-AzRoleAssignment -RoleDefinitionName $MonitoringMetricsRoleDefinitionName -Scope $AKSClusterResourceId -ErrorVariable notPresent -ErrorAction SilentlyContinue

            if ($notPresent) {
                Write-Host("Error in fetching monitoring metrics publisher candidates for " + $AKSClusterName) -ForegroundColor Red;
                Write-Host($notPresent);
                Write-Host("");
            }
            else {
                $TryToOnboardToCustomMetrics = "false";
                if ($MonitoringMetricsPublisherCandidates) {
                    Write-Host($MonitoringMetricsPublisherCandidates | Format-List | Out-String);

                    $totalCandidates = $MonitoringMetricsPublisherCandidates.ObjectId.Length;
                    $metricsPublisherRoleAlreadyExists = "false";

                    for ($index = 0; $index -lt $totalCandidates; $index++) {
                        if ($MonitoringMetricsPublisherCandidates.ObjectId[$index] -eq $clusterSPNObjectID) {
                            $metricsPublisherRoleAlreadyExists = "true";
                        }
                    }

                    if ($metricsPublisherRoleAlreadyExists -eq "true") {
                        Write-Host("Cluster SPN has the Monitoring Metrics Publisher Role assigned already") -ForegroundColor Green;
                    }
                    else {
                        $TryToOnboardToCustomMetrics = "true";
                    }
                }
                else {
                    Write-Host("No monitoring metrics publisher candidates present, We need to onboard the cluster service prinicipal to the Monitoring Metrics Publisher role");
                    $TryToOnboardToCustomMetrics = "true";
                }
                if ($TryToOnboardToCustomMetrics -eq "true") {
                    $message = "Detected that custom metrics is not enabled for this cluster. You need to be an owner on the cluster resource to do the following operation operation.";
                    Write-Host($message);
                    $question = " Do you want this script to enable it by adding the role 'Monitoring Metrics Publisher' to your clusters SPN?"

                    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
                    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
                    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

                    $decision = $Host.UI.PromptForChoice($message, $question, $choices, 0);

                    if ($decision -eq 0) {
                        $AssignRoleAssignment = New-AzRoleAssignment -ObjectId $clusterSPNObjectID -Scope $AKSClusterResourceId -RoleDefinitionName $MonitoringMetricsRoleDefinitionName -ErrorAction SilentlyContinue -ErrorVariable assignmentFailed;
                        if ($assignmentFailed) {
                            Write-Host("Couldn't assign the new role. You need the cluster owner role to do this action. Please contact your cluster administrator to onboard.") -ForegroundColor Red;
                            Write-Host("You can find more information on this here: https://aka.ms/ci-enable-mdm") -ForegroundColor Red;
                            Write-Host("");
                        }
                        else {
                            Write-Host("Successfully onboarded to Azure monitor for containers custom metrics.") -ForegroundColor Green
                            Write-Host("");
                        }
                    }
                }
            }
        }
    }
    else {
        Write-Host('Cluster is in a location where Custom metrics are not available') -ForegroundColor Red;
        Write-Host("");
    }
}
catch {
    Write-Host("Error in fetching Cluster details for " + $AKSClusterName) -ForegroundColor Red;
    Write-Host("Please check that you have access to the cluster: " + $AKSClusterName) -ForegroundColor Red;
    Write-Host("");
}

if ($null -eq $LogAnalyticsWorkspaceResourceID) {
    Write-Host("")
    Write-Host("Onboarded  log analytics workspace to this cluster either deleted or moved.This requires Opt-out and Opt-in back to Monitoring") -ForegroundColor Red
    Write-Host("Please try to opt out of monitoring and opt-in following the instructions in below links:") -ForegroundColor Red
    Write-Host("Opt-out - " + $OptOutLink) -ForegroundColor Red
    Write-Host("Opt-in - " + $OptInLink) -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}
else {

    Write-Host("Configured LogAnalyticsWorkspaceResourceId: : '" + $LogAnalyticsWorkspaceResourceID + "' ") 
    $workspaceSubscriptionId = $LogAnalyticsWorkspaceResourceID.split("/")[2]
    $workspaceResourceGroupName = $LogAnalyticsWorkspaceResourceID.split("/")[4]
    $workspaceName = $LogAnalyticsWorkspaceResourceID.split("/")[8]

    try {
        if ($SubscriptionId -ne $workspaceSubscriptionId) {
            Write-Host("Changing to workspace's subscription")
            Select-AzSubscription -SubscriptionId $workspaceSubscriptionId
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
        Get-AzSubscription -SubscriptionId $workspaceSubscriptionId -ErrorAction Stop
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
    Get-AzResourceGroup -Name $workspaceResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
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
        $WorkspaceInformation = Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName -ErrorAction Stop
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

            $CurrentDir = (Get-Item -Path ".\" -Verbose).FullName
            $TemplateFile = $CurrentDir + "\ContainerInsightsSolution.json"
            $DeploymentName = "ContainerHealthOnboarding-Solution-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
            $Parameters = @{}
            $Parameters.Add("workspaceResourceId", $LogAnalyticsWorkspaceResourceID)
            $Parameters.Add("workspaceRegion", $WorkspaceLocation)

            $Parameters

            try {
                New-AzResourceGroupDeployment -Name $DeploymentName `
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
