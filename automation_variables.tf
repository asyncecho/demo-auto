variable "azure_subscriptionid" {
  description = "Azure Subscription ID.  Required in AzureRM > 4"
  type        = string
  nullable    = false
}

variable "subscription_name" {
  description = "Azure Subscription Name.  Required for Azure Automation module"
  type        = string
  nullable    = false
}


variable "azure_tenantid" {
  description = "Azure Tenant ID.  Can be retrieved from EntraID panel"
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
}

variable "script_file_path" {
  description = "Relative path to the PowerShell script (e.g., './src/psscriptfile.ps1')"
  type        = string
  sensitive   = true
}

variable "start_time_utc" {
  description = "The UTC time for schedule execution in HH:MM:SS format"
  type        = string

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$", var.start_time_utc))
    error_message = "Time must be in HH:MM:SS format (24-hour clock)"
  }
}


variable "runbook_description" {
  description = "Runbook description visible in the rubook's settings"
  type        = string
  sensitive   = true
}

variable "runbook_type" {
  description = "The type of runbook to create. Allowed values: Graph, GraphPowerShell, GraphPowerShellWorkflow, PowerShellWorkflow, PowerShell, PowerShell72, Python3, Python2, Script"
  type        = string

  validation {
    condition = contains([
      "Graph",
      "GraphPowerShell",
      "GraphPowerShellWorkflow",
      "PowerShellWorkflow",
      "PowerShell",
      "PowerShell72",
      "Python3",
      "Python2",
      "Script"
    ], var.runbook_type)
    error_message = "The runbook_type must be one of: Graph, GraphPowerShell, GraphPowerShellWorkflow, PowerShellWorkflow, PowerShell, PowerShell72, Python3, Python2, Script."
  }
}


variable "dcr_name" {
  description = "Name of the Data Collection Rule for ingestion of data"
  type        = string
}

variable "dcr_stream_name" {
  description = "Stream in the Data Collection Rule for data ingestion"
  type        = string
}

variable "runbook_name" {
  description = "Azure Automation Runbook name"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Automation Resource Group"
  type        = string
}

variable "automation_account_name" {
  description = "Azure Automation Resource Name"
  type        = string
}

variable "hybrid_worker_group" {
  description = "Azure Automation Resource Name"
  type        = string
  default     = ""
}


variable "secret_name_sp_app_id" {
  description = "Key vault object name for AppID with permission to contribute to DCR. Needed for the script"
  type        = string
  default     = null
}

variable "secret_name_sp_password" {
  description = "Key vault object name for AppID password to contribute to DCR. Needed for the script"
  type        = string
  default     = null
}

variable "keyvault_name" {
  description = "Name of the keyvault for Azure Automation Secrets"
  type        = string
}