/*  ****   IMPORTANT  *****
make shure that PROXY is properly configured in PowerShell before running the scipts

$env:HTTP_PROXY='http://proxy.airplus.net:8080'            
$env:HTTPS_PROXY="http://proxy.airplus.net:8080"

for a permanent change add those lines to $profile in PowerShell

*/
terraform {
  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.25.0"
    }

    azapi = {
      source  = "azure/azapi"
      version = "=2.3.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "3.3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscriptionid
  tenant_id       = var.azure_tenantid
}

provider "azapi" {
  default_location = var.location
}

provider "azuread" {
  tenant_id = var.azure_tenantid
}