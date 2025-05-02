variable "runbook_name" {
  description = "The name of the Automation Runbook"
  type        = string
}

variable "azure_tenantid" {
  description = "Tenant ID (required for MSGraph in the script)"
  type        = string
}

variable "subscription_name" {
  description = "The name of the subscription in which the Automation Account is located"
  type        = string
}


variable "resource_group_name" {
  description = "The name of the resource group in which the Automation Account is located"
  type        = string
}

variable "automation_account_name" {
  description = "The name of the Automation Account"
  type        = string
}

variable "location" {
  description = "The location/region where the runbook will be created"
  type        = string
}

variable "description" {
  description = "The description of the Automation Runbook"
  type        = string
  default     = ""
}

variable "log_verbose" {
  description = "Whether verbose log should be enabled"
  type        = bool
  default     = false
}

variable "log_progress" {
  description = "Whether progress log should be enabled"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "hybrid_worker_group" {
  description = "The name of the hybrid worker group to run the job on"
  type        = string
  default     = null
}

variable "script_file_path" {
  description = "Absolute path to the PowerShell script file"
  type        = string
}

variable "schedule_start_time" {
  description = "The UTC time for schedule execution in YYYY-MM-DDT09:00:00Z format"
  type        = string
}

variable "keyvault_name" {
  description = "Name of the keyvault for Azure Automation Secrets"
  type        = string
}

variable "time_suffix" {
  description = "Unique key that changes when time configuration changes"
  type        = string
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
  default     = null
}

variable "dcr_stream_name" {
  description = "Stream in the Data Collection Rule for data ingestion"
  type        = string
  default     = null
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
