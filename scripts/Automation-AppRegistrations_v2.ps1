# Please use lowercase parameters for better terraform integration
# see https://github.com/Azure/azure-sdk-for-go/issues/4780  for details

param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $azure_tenantid,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $subscription_name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $resource_group_name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $keyvault_name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $dcr_name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $dcr_stream_name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $kv_sp_client_id_name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String] $kv_sp_client_secret_name
)

function Invoke-Safe {
    param (
        [scriptblock]$scriptblock,
        [string]$errormessage
    )
    try {
        & $scriptblock
    }
    catch {
        Write-Error "[$(Get-Date -Format 'u')] $errormessage - $($_.Exception.Message)"
        throw
    }
}

# Function to ensure required modules are available
function Test-ModuleInstalled {
    param (
        [string]$ModuleName,
        [string]$ModuleVersion = "latest"
    )
    # Check if the module is already installed
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Output "Module '$ModuleName' is not installed. Attempting to install..."
        try {
            # Install the module from PSGallery
            if ($ModuleVersion -eq "latest") {
                Install-Module -Name $ModuleName -Force -AllowClobber
            }
            else {
                Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Force -Scope CurrentUser -AllowClobber
            }
            Write-Information "Module '$ModuleName' installed successfully."
        }
        catch {
            Write-Error "Failed to install module '$ModuleName'. Error: $_"
            throw
        }
    }
    else {
        Write-Information "Module '$ModuleName' is already installed."
    }
}

Function Write-AppRegistrations {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Items, # The collection of secrets or certificates
        [Parameter(Mandatory = $true)]
        [string]$CrdntlType, # Type of credential (e.g., "PasswordCredentials")
        [object]$AzureApp = $AzureApp, # The Azure app object that contains the AppId
        [object]$AzureAppOwners = $AzureAppOwners, # Application Owners
        [int]$ExpiresIn = 90, # Include objects exiring in the next $ExpireIn days
        [datetime]$CurrentDate = $CurrentDate         # Time the script run
    )

    # Get the item with the latest ExpiryDate
    $latestItem = $Items | Sort-Object -Property EndDateTime -Descending | Select-Object -First 1

    # Get the item with the oldest ExpiryDate within the defined period
    $oldestItem = $Items | Where-Object { ($_.EndDateTime -ge $currentDate) -and ($_.EndDateTime -le $currentDate.AddDays($ExpiresIn)) }


    # Proceed only if an oldest item is found
    if ($oldestItem) {
        $LatestExpiryDate = $null
        if ($oldestItem.EndDateTime -ne $latestItem.EndDateTime) { $LatestExpiryDate = ($latestItem.EndDateTime).GetDateTimeFormats()[105] }
        $script:credentials = [PSCustomObject] @{
            TimeGenerated    = $CurrentDate.GetDateTimeFormats()[105];
            CredentialID     = $oldestItem.KeyId;
            CredentialType   = $CrdntlType;
            DisplayName      = $AzureApp.DisplayName;
            AppId            = $AzureApp.AppId;
            ExpiryDate       = ($oldestItem.EndDateTime).GetDateTimeFormats()[105];
            StartDate        = ($oldestItem.StartDateTime).GetDateTimeFormats()[105];
            #LatestExpiryDate  = ($latestItem.EndDateTime).GetDateTimeFormats()[105]; # From the newest item
            LatestExpiryDate = $LatestExpiryDate;
            Owners           = $AzureAppOwners.AdditionalProperties.userPrincipalName;
            # OwnersDisplayname = Foreach($Owner in $AzureAppOwners) {Get-MgUser -UserId $Owner.Id | Select-Object DisplayName, Mail };
            Link             = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/" + $AzureApp.AppId;
            BAP              = ($AzureApp.ServiceManagementReference -split ":")[-1];
        }
        
        # Convert to JSON and output
        $credentials = @($credentials)
        $jsonData = ConvertTo-Json -InputObject $credentials -Depth 5
        #Write-Information "Writing to the log - $($AzureApp.DisplayName)"
        #Write-Information "JSON Data..."
        #Write-Information $jsonData
        
        Invoke-RestMethod -Uri $uri -Method "Post" -Body $jsonData -Headers $headers

    }
}

function Get-KeyVaultSecretPlainText {
    param (
        [Parameter(Mandatory = $true)][string]$vault,
        [Parameter(Mandatory = $true)][string]$secretname
    )
    try {
        return Get-AzKeyVaultSecret -VaultName $vault -Name $secretname -AsPlainText -ErrorAction Stop
    }
    catch {
        Write-Error "[$(Get-Date -Format 'u')] Failed to retrieve secret '$secretname' from vault '$vault': $_"
        throw
    }
}

<#
function Add-Credentials {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Items, # The collection of secrets or certificates
        [Parameter(Mandatory = $true)]
        [string]$CrdntlType, # Type of credential (e.g., "PasswordCredentials")
        [object]$AzureApp = $AzureApp, # The Azure app object that contains the AppId
        [object]$AzureAppOwners = $AzureAppOwners, # Application Owners
        [int]$ExpiresIn = 90, # Include objects exiring in the next $ExpireIn days
        [datetime]$CurrentDate = $CurrentDate         # Time the script run
    )

    foreach ($item in $Items) {
        #Write-Output "$($AzureApp.DisplayName) - $CrdntlType expires on $($item.EndDateTime)"
        if (($item.EndDateTime -lt $CurrentDate.AddDays($ExpiresIn)) -and ($item.EndDateTime -ge $CurrentDate)) {
            write-Output  "$($AzureApp.DisplayName)  matches criteria for logging" -ForegroundColor Green
            $script:credentials = [PSCustomObject] @{
                TimeGenerated    = $CurrentDate.GetDateTimeFormats()[105];
                CredentialID     = $item.KeyId;
                CredentialType   = $CrdntlType;
                DisplayName      = $AzureApp.DisplayName;
                AppId            = $AzureApp.AppId;
                ExpiryDate       = ($item.EndDateTime).GetDateTimeFormats()[105];
                StartDate        = ($item.StartDateTime).GetDateTimeFormats()[105];
                LatestExpiryDate = ($item.EndDateTime).GetDateTimeFormats()[105];
                Owners           = $AzureAppOwners.AdditionalProperties.userPrincipalName;
                # OwnersDisplayname = Foreach($Owner in $AzureAppOwners) {Get-MgUser -UserId $Owner.Id | Select-Object DisplayName, Mail };
                Link             = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/" + $AzureApp.AppId;
                BAP              = ($AzureApp.ServiceManagementReference -split ":")[-1];
            }

            $credentials = @($credentials)
            $jsonData = ConvertTo-Json -InputObject $credentials -Depth 5
            Write-Information "Writing to the log - $($AzureApp.DisplayName)"
            
            Invoke-RestMethod -Uri $uri -Method "Post" -Body $jsonData -Headers $headers
	
            # Write-Information "JSON Data..."
            # Write-Information $jsonData
            
        }
    }
}
#>

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process  | Out-Null

# Import required modules
# Define required modules at the top
$requiredModules = @(
    "Az.Accounts",
    "Az.KeyVault",
    "Microsoft.Graph.Applications",
    "Microsoft.Graph.Authentication"
)

# Install them in a loop
$requiredModules | ForEach-Object {
    Test-ModuleInstalled -modulename $_
}

<#
# Replaced with Invoke-Safe function
# Login to Azure using the Managed Identity of the Automation Account
try {
    "Logging in to Azure..."
    Connect-AzAccount -Identity  -Subscription $subscription_name | Out-Null
    # Connect-AzAccount -Identity
    #Connect-AzAccount -Identity -Subscription $subscription_name | Out-Null
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
#>

# Connect to Azure
Invoke-Safe -scriptblock {
    Connect-AzAccount -Identity -Subscription $subscription_name | Out-Null
} -errormessage "Azure login failed"


function Get-DCRBearerToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$tenantId,
        [Parameter(Mandatory = $true)][string]$clientId,
        [Parameter(Mandatory = $true)][string]$clientSecret
    )

    Add-Type -AssemblyName System.Web
    $scope = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")
    $body = "client_id=$clientId&scope=$scope&client_secret=$clientSecret&grant_type=client_credentials"
    $headers = @{ "Content-Type" = "application/x-www-form-urlencoded" }
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

    $tokenResponse = Invoke-Safe -ScriptBlock {
        Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers
    } -ErrorMessage "Failed to retrieve DCR bearer token."

    return $tokenResponse.access_token
}


# Retrieve the secret from the Key Vault
# Retrieve secrets
$kv_sp_client_id_name_value = Get-KeyVaultSecretPlainText -vault $keyvault_name -secretname $kv_sp_client_id_name
$kv_sp_client_secret_name_value = Get-KeyVaultSecretPlainText -vault $keyvault_name -secretname $kv_sp_client_secret_name

#Get Data Collection Rule info
$DCR = Invoke-Safe -scriptblock {
    Get-AzResource -ResourceGroupName $resource_group_name -ResourceType "Microsoft.Insights/dataCollectionRules" -ResourceName $dcr_name
} -errormessage "Failed to get Data Collection Rule"

$DCRImmutableId = $DCR.Properties.immutableId
$DCRLogIngestionEndpoint_uri = $DCR.Properties.endpoints.logsIngestion

Write-Output "*****************************"
Write-Output "DCR ImmutableID: $DCRImmutableId"
Write-Output "DCR Log Ingestion Endpoint: $DCRLogIngestionEndpoint_uri"
Write-Output "*****************************"



# Graph login,  Currnlty working
$SPPassword = ConvertTo-SecureString $kv_sp_client_secret_name_value -AsPlainText -Force
$spCredentials = New-Object System.Management.Automation.PSCredential ($kv_sp_client_id_name_value, $SPPassword)

<# 
# Graph Login to try Securely retrieve secret from Key Vault
$spClientSecretObj = Get-AzKeyVaultSecret -VaultName $keyvault_name -Name $kv_sp_client_secret_name
$SPPassword = $spClientSecretObj.SecretValue

# Build credential object
#$spCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $kv_sp_client_id_name_value, $SPPassword
#>

Invoke-Safe -scriptblock {
    Connect-MgGraph -TenantId $azure_tenantid -ClientSecretCredential $spCredentials -NoWelcome
} -errormessage "Failed to connect to Microsoft Graph"

# Immediately clear after use
Remove-Variable -Name SPPassword, spClientSecretObj, spCredential -Force -ErrorAction SilentlyContinue

# Initialize connection to a Data Collection Rule


<# Moved to the Get-DCRBearerToken function

    Add-Type -AssemblyName System.Web  #adds a required assembly to build a $scope variable
    # Obtain a bearer token used later to authenticate against the DCR.
    $scope = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
    $body = "client_id=$kv_sp_client_id_name_value&scope=$scope&client_secret=$kv_sp_client_secret_name_value&grant_type=client_credentials";
    $headers = @{"Content-Type" = "application/x-www-form-urlencoded" };
    $uri = "https://login.microsoftonline.com/$azure_tenantid/oauth2/v2.0/token"

    $bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
#>

$bearerToken = Get-DCRBearerToken `
        -tenantid     $azure_tenantid `
        -clientid     $kv_sp_client_id_name_value `
        -clientsecret $kv_sp_client_secret_name_value

$headers = @{
    "Authorization" = "Bearer $bearerToken"
    "Content-Type"  = "application/json"
}
$uri = "$DCRLogIngestionEndpoint_uri/dataCollectionRules/$DCRImmutableId/streams/$($dcr_stream_name)?api-version=2023-01-01"

# Write-Output "Body:   $body"
Write-Information "Endpoint URI: $uri"

#only for debug
#Get-MgContext

#$AllAzureApps = Get-MgApplication -Top 35
$AllAzureApps = Get-MgApplication -all:$True
Write-Information "Retrieved $($AllAzureApps.Count) Apps"

$credentials = @()
$CurrentDate = Get-Date ([datetime]::UtcNow)

Foreach ($AzureApp in $AllAzureApps) {
    $Secrets = $AzureApp.PasswordCredentials
    # $Certificates = $AzureApp.KeyCredentials  # <- future use

    $AzureAppOwners = Get-MgApplicationOwner -ApplicationId $AzureApp.ID

    # If ($Secrets.Count -gt 0) {Add-Credentials -Items $Secrets -CredentialType "Secret"}
    # if ($Certificates.Count -gt 0) {Add-Credentials -Items $Certificates -CredentialType "Certificate"}

    if ($Secrets.Count -gt 0) {
        Write-AppRegistrations `
            -items             $Secrets `
            -CrdntlType	       "Secret" `
            -azureapp          $AzureApp `
            -azureappowners    $AzureAppOwners `
            -currentdate       $CurrentDate `
            -expiresin         90
    }
    
}

Write-Output "Completed"
