# Please use lowercase parameters for better terraform integration
# see https://github.com/Azure/azure-sdk-for-go/issues/4780  for details
param
 (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String] $azure_tenantid,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $subscription_name,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $resource_group_name,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $key_vault_name,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $dcr_name,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $dcr_stream_name,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $secret_name_sp_app_id,

     [Parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]
     [String] $secret_name_sp_password
 )


# Function to ensure required modules are available
function Check-ModuleInstalled {
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
            } else {
                Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Force -Scope CurrentUser -AllowClobber
            }
            Write-Output "Module '$ModuleName' installed successfully."
        } catch {
            Write-Error "Failed to install module '$ModuleName'. Error: $_"
            throw
        }
    }
    else {
        Write-Output "Module '$ModuleName' is already installed."
    }
}

Function Log-AppRegistrations {
    param (
        [Parameter(Mandatory=$true)]
            [array]$Items,                          # The collection of secrets or certificates
        [Parameter(Mandatory=$true)]
            [string]$CredentialType,                # Type of credential (e.g., "PasswordCredentials")
        [object]$AzureApp=$AzureApp,                # The Azure app object that contains the AppId
        [object]$AzureAppOwners=$AzureAppOwners,     # Application Owners
        [int]$ExpiresIn = 90,                        # Include objects exiring in the next $ExpireIn days
        [datetime]$CurrentDate=$CurrentDate         # Time the script run
    )

     # Get the item with the latest ExpiryDate
    $latestItem = $Items | Sort-Object -Property EndDateTime -Descending | Select-Object -First 1

    # Get the item with the oldest ExpiryDate within the defined period
    $oldestItem = $Items | Where-Object { ($_.EndDateTime -ge $currentDate) -and ($_.EndDateTime -le $currentDate.AddDays($ExpiresIn))}


    # Proceed only if an oldest item is found
    if ($oldestItem) {
        $LatestExpiryDate  = $null
        if($oldestItem.EndDateTime -ne $latestItem.EndDateTime){ $LatestExpiryDate = ($latestItem.EndDateTime).GetDateTimeFormats()[105]}
        $script:credentials = [PSCustomObject] @{
            TimeGenerated = $CurrentDate.GetDateTimeFormats()[105];
            CredentialID =$oldestItem.KeyId;
            CredentialType = $CredentialType;
            DisplayName = $AzureApp.DisplayName;
            AppId = $AzureApp.AppId;
            ExpiryDate = ($oldestItem.EndDateTime).GetDateTimeFormats()[105];
            StartDate = ($oldestItem.StartDateTime).GetDateTimeFormats()[105];
            #LatestExpiryDate  = ($latestItem.EndDateTime).GetDateTimeFormats()[105]; # From the newest item
            LatestExpiryDate  = $LatestExpiryDate;
            Owners = $AzureAppOwners.AdditionalProperties.userPrincipalName;
            # OwnersDisplayname = Foreach($Owner in $AzureAppOwners) {Get-MgUser -UserId $Owner.Id | Select-Object DisplayName, Mail };
            Link = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/"+$AzureApp.AppId;
            BAP = ($AzureApp.ServiceManagementReference -split ":")[-1];
        }
        
        # Convert to JSON and output
        $credentials = @($credentials)
        $jsonData = ConvertTo-Json -InputObject $credentials -Depth 5
        #Write-Output "Writing to the log - $($AzureApp.DisplayName)"
		    #Write-Output "JSON Data..."
        #Write-Output $jsonData
        
        $uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $jsonData -Headers $headers

        #Write-Output "Upload Response: $uploadResponse" 

        }
}

function Add-Credentials {
    param (
        [Parameter(Mandatory=$true)]
            [array]$Items,                          # The collection of secrets or certificates
        [Parameter(Mandatory=$true)]
            [string]$CredentialType,                # Type of credential (e.g., "PasswordCredentials")
        [object]$AzureApp=$AzureApp,                # The Azure app object that contains the AppId
        [object]$AzureAppOwners=$AzureAppOwners,     # Application Owners
        [int]$ExpiresIn = 90,                        # Include objects exiring in the next $ExpireIn days
        [datetime]$CurrentDate=$CurrentDate         # Time the script run
    )

    foreach ($item in $Items) {
        #Write-Host "$($AzureApp.DisplayName) - $CredentialType expires on $($item.EndDateTime)"
        if(($item.EndDateTime -lt $CurrentDate.AddDays($ExpiresIn)) -and ($item.EndDateTime -ge $CurrentDate))  {
            write-Host  "$($AzureApp.DisplayName)  matches criteria for logging" -ForegroundColor Green
        $script:credentials = [PSCustomObject] @{
            TimeGenerated = $CurrentDate.GetDateTimeFormats()[105];
            CredentialID =$item.KeyId;
            CredentialType = $CredentialType;
            DisplayName = $AzureApp.DisplayName;
            AppId = $AzureApp.AppId;
            ExpiryDate = ($item.EndDateTime).GetDateTimeFormats()[105];
            StartDate = ($item.StartDateTime).GetDateTimeFormats()[105];
            LatestExpiryDate  = ($item.EndDateTime).GetDateTimeFormats()[105];
            Owners = $AzureAppOwners.AdditionalProperties.userPrincipalName;
            # OwnersDisplayname = Foreach($Owner in $AzureAppOwners) {Get-MgUser -UserId $Owner.Id | Select-Object DisplayName, Mail };
            Link = "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/"+$AzureApp.AppId;
            BAP = ($AzureApp.ServiceManagementReference -split ":")[-1];
        }

        $credentials = @($credentials)
        $jsonData = ConvertTo-Json -InputObject $credentials -Depth 5
        Write-Output "Writing to the log - $($AzureApp.DisplayName)"
        $uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $jsonData -Headers $headers
	
        Write-Output
        Write-Output
		Write-Output "JSON Data..."
        Write-Output $jsonData
        Write-Output

    }
    }
}

# Ensures you do not inherit an AzContext in your runbook
"Disable-AzContextAutosave -Scope Process"
Disable-AzContextAutosave -Scope Process  | Out-Null


# Import required modules
    "Az.Accounts"
Check-ModuleInstalled -ModuleName "Az.Accounts"
Check-ModuleInstalled -ModuleName "Az.KeyVault"
Check-ModuleInstalled -ModuleName "Microsoft.Graph.Applications"
Check-ModuleInstalled -ModuleName "Microsoft.Graph.Authentication"

# Login to Azure using the Managed Identity of the Automation Account
try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity  -Subscription $subscription_name | Out-Null
    # Connect-AzAccount -Identity
    #Connect-AzAccount -Identity -Subscription $subscription_name | Out-Null
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}


# Retrieve the secret from the Key Vault
try {
    # Ensure the Key Vault exists in the resource group
    $KeyVault = Get-AzKeyVault -ResourceGroupName $resource_group_name -VaultName $key_vault_name -ErrorAction Stop

    # Get the secret value
    #$secret_TenantID_value = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_TenantID -AsPlainText -ErrorAction Stop
    $secret_name_sp_app_id_value = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name_sp_app_id -AsPlainText -ErrorAction Stop
    $secret_name_sp_password_value = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name_sp_password -AsPlainText -ErrorAction Stop
}
catch {
    # Handle any errors during the process
    Write-Error "Failed to retrieve the secret from the Key Vault: $_"
}


#Get Data Collection Rule info
try 
{
    $DCR = Get-AzResource -ResourceGroupName $resource_group_name -ResourceType "Microsoft.Insights/dataCollectionRules" -ResourceName $dcr_name
    $DCRImmutableId = $DCR.Properties.immutableId
    $DCRLogIngestionEndpoint_uri = $DCR.Properties.endpoints.logsIngestion

    Write-Output "*****************************"
    Write-Output "DCR ImmutableID: $DCRImmutableId"
    Write-Output "DCR Log Ingestion Endpoint: $DCRLogIngestionEndpoint_uri"
    Write-Output "*****************************"
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Connect to Microsoft Graph
try {
    # Convert the Service Principal secret to secure string
    $SPPassword = ConvertTo-SecureString $secret_name_sp_password_value -AsPlainText -Force

    # Create a new credentials object containing the application ID and password that will be used to authenticate
    $spCredentials = New-Object System.Management.Automation.PSCredential ($secret_name_sp_app_id_value, $SPPassword)

    # Authenticate with the credentials object
    Connect-MgGraph -TenantId $azure_tenantid -ClientSecretCredential $spCredentials -NoWelcome
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Initialize connection to a Data Collection Rule

	Add-Type -AssemblyName System.Web  #adds a required assembly to build a $scope variable
	# Obtain a bearer token used later to authenticate against the DCR.
    $scope= [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
    $body = "client_id=$secret_name_sp_app_id_value&scope=$scope&client_secret=$secret_name_sp_password_value&grant_type=client_credentials";
    $headers = @{"Content-Type"="application/x-www-form-urlencoded"};
    $uri = "https://login.microsoftonline.com/$azure_tenantid/oauth2/v2.0/token"

    $bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token
    $headers = @{"Authorization"="Bearer $bearerToken";"Content-Type"="application/json"};
    $uri = "$DCRLogIngestionEndpoint_uri/dataCollectionRules/$DCRImmutableId/streams/$($dcr_stream_name)?api-version=2023-01-01"

    # Write-Output "Body:   $body"
    Write-Output "Endpoint URI: $uri"


#only for debug
#Get-MgContext

#$AllAzureApps = Get-MgApplication -Top 35
$AllAzureApps = Get-MgApplication -all:$True
Write-Output "Retrieved $($AllAzureApps.Count) Apps"

$credentials = @()
$CurrentDate = Get-Date ([datetime]::UtcNow)

Foreach ($AzureApp in $AllAzureApps)
{
    $Secrets = $AzureApp.PasswordCredentials
    $Certificates = $AzureApp.KeyCredentials
    $AzureAppOwners = Get-MgApplicationOwner -ApplicationId $AzureApp.ID

   # If ($Secrets.Count -gt 0) {Add-Credentials -Items $Secrets -CredentialType "Secret"}
   # if ($Certificates.Count -gt 0) {Add-Credentials -Items $Certificates -CredentialType "Certificate"}

   If ($Secrets.Count -gt 0) {Log-AppRegistrations -Items $Secrets -CredentialType "Secret"}
    
}

Write-Output "Completed"
