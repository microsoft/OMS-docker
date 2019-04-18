<# 
    .DESCRIPTION 
    .PARAMETER aksResourceId
        Name of the cluster configured on the OMSAgent
    .PARAMETER loganalyticsWorkspaceResourceId
        Azure ResourceId of the log analytics workspace Id
#>
param(
    [Parameter(mandatory = $true)]
    [string]$aksResourceId,
    [Parameter(mandatory = $true)]
    [string]$aksResourceLocation,
    [Parameter(mandatory = $true)]
    [string]$logAnalyticsWorkspaceResourceId
)

# checks the required Powershell modules exist and if not exists, request the user permission to install
$azAccountModule = Get-Module -ListAvailable -Name Az.Accounts
$azResourcesModule = Get-Module -ListAvailable -Name Az.Resources
$azOperationalInsights = Get-Module -ListAvailable -Name Az.OperationalInsights

if (($null -eq $azAccountModule) -or ($null -eq $azResourcesModule) -or ($null -eq $azOperationalInsights)) {
    
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

if ([string]::IsNullOrEmpty($logAnalyticsWorkspaceResourceId)) {   
    Write-Host("logAnalyticsWorkspaceResourceId should not be NULL or empty") -ForegroundColor Red
    exit
}

if (($logAnalyticsWorkspaceResourceId -match "/providers/Microsoft.OperationalInsights/workspaces") -eq $false) {
    Write-Host("logAnalyticsWorkspaceResourceId should be valid Azure Resource Id format") -ForegroundColor Red
    exit
}

$workspaceResourceDetails = $logAnalyticsWorkspaceResourceId.Split("/")

if ($workspaceResourceDetails.Length -ne 9) { 
    Write-Host("logAnalyticsWorkspaceResourceId should be valid Azure Resource Id format") -ForegroundColor Red
    exit
}

$workspaceSubscriptionId = $workspaceResourceDetails[2]
$workspaceSubscriptionId = $workspaceSubscriptionId.Trim()

$workspaceResourceGroupName = $workspaceResourceDetails[4]
$workspaceResourceGroupName = $workspaceResourceGroupName.Trim()

$workspaceName = $workspaceResourceDetails[8]
$workspaceResourceGroupName = $workspaceResourceGroupName.Trim()

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
        Write-Host("Subscription: $SubscriptionId is already selected. Account details: ")
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

# validate specified logAnalytics workspace exists and got access permissions
Write-Host("Checking specified logAnalyticsWorkspaceResourceId exists and got access...")

try {
    $WorkspaceInformation = Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName -ErrorAction Stop
}
catch {
    Write-Host("")
    Write-Host("Could not fetch details for the workspace : '" + $workspaceName + "'. Please make sure that it hasn't been deleted and you have access to it.") -ForegroundColor Red        
    Stop-Transcript
    exit
}

Write-Host("Successfully verified specified logAnalyticsWorkspaceResourceId valid and exists...") -ForegroundColor Green

$WorkspaceLocation = $WorkspaceInformation.Location
		
if ($null -eq $WorkspaceLocation) {
    Write-Host("")
    Write-Host("Cannot fetch workspace location. Please try again...") -ForegroundColor Red
    Write-Host("")
    Stop-Transcript
    exit
}

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
	
if ($false -eq $isSolutionOnboarded) {

    $DeploymentName = "ContainerInsightsSolutionOnboarding-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
    $Parameters = @{}
    $Parameters.Add("workspaceResourceId", $logAnalyticsWorkspaceResourceID)
    $Parameters.Add("workspaceRegion", $WorkspaceLocation)
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
    
}

Write-Host("Successfully added Container Insights Solution to workspace" + $workspaceName)  -ForegroundColor Green

try {
    $DeploymentName = "ClusterHealthOnboarding-" + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')
    $Parameters = @{}
    $Parameters.Add("aksResourceId", $aksResourceId)
    $Parameters.Add("aksResourceLocation", $aksResourceLocation)
    $Parameters.Add("workspaceResourceId", $logAnalyticsWorkspaceResourceId)

    
    New-AzResourceGroupDeployment -Name $DeploymentName `
        -ResourceGroupName $workspaceResourceGroupName `
        -TemplateUri  https://raw.githubusercontent.com/Microsoft/OMS-docker/dilipr/onboardHealth/health/customOnboarding.json `
        -TemplateParameterObject $Parameters -ErrorAction Stop`
    Write-Host("")
        
    Write-Host("Successfully custom onboarded cluster to Monitoring") -ForegroundColor Green

    Write-Host("")
}
catch {
    Write-Host ("Template deployment failed with an error: '" + $Error[0] + "' ") -ForegroundColor Red
    #Write-Host("Please contact us by emailing askcoin@microsoft.com for help") -ForegroundColor Red
}  


$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

if (-not (test-path $desktopPath\deployments) ) {
    Write-Host "$($desktopPath)\deployments doesn't exist, creating it"
    mkdir $desktopPath\deployments|out-null
} else {
    Write-Host "$($desktopPath)\deployments exists, no need to create it"
}


try {

    $aksResourceDetails = $aksResourceId.Split("/")
    

    if ($aksResourceDetails.Length -ne 9) { 
        Write-Host("aksResourceDetails should be valid Azure Resource Id format") -ForegroundColor Red
        exit
    }

    $clusterName = $aksResourceDetails[8].Trim()
    $clusterResourceGroupName = $aksResourceDetails[4].Trim()

    az aks get-credentials -n $clusterName -g $clusterResourceGroupName
    
    $key = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspaceResourceGroupName -Name $workspaceName).PrimarySharedKey
    $wsid = $WorkspaceInformation.CustomerId
    $base64EncodedKey = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($key))
    $base64EncodedWsId = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($wsid))
    Invoke-WebRequest https://raw.githubusercontent.com/Microsoft/OMS-docker/dilipr/onboardHealth/health/omsagent-template.yaml -OutFile $desktopPath\omsagent-template.yaml
    (Get-Content -Path $desktopPath\omsagent-template.yaml -Raw) -replace 'VALUE_AKS_RESOURCE_ID', $aksResourceId -replace 'VALUE_AKS_REGION', $aksRegion -replace 'VALUE_WSID', $base64EncodedWsId -replace 'VALUE_KEY', $base64EncodedKey  | Set-Content $desktopPath\deployments\omsagent-$clusterName.yaml
    kubectl delete -f $desktopPath\deployments\omsagent-$clusterName.yaml
    kubectl apply -f $desktopPath\deployments\omsagent-$clusterName.yaml
}
catch {
    Write-Host ("Agent deployment failed with an error: '" + $Error[0] + "' ") -ForegroundColor Red
}

Write-Host "Upgraded omsagent"

