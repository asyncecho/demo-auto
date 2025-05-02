variable "azure_subscriptionid" {
  description = "Azure Subscription ID.  Required in AzureRM > 4"
  type        = string
  nullable    = false
}

variable "azure_tenantid" {
  description = "Azure Tenant ID.  Can be retrieved from EntraID panel"
  type        = string
  nullable    = false
}

variable "application_id" {
  description = "Application (Client) ID from EntraID for RBAC Role assignment"
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "westeurope"
}

variable "law_name" {
  description = "Name of the existing Log Analytics Workspace"
  type        = string
  nullable    = false
  default     = ""
}

variable "law_resource_group_name" {
  description = "Resource group name of the existing Log Analytics Workspace"
  type        = string
  default     = ""
}

variable "table_name" {
  description = "Name of the table to create (must end with _CL for custom logs)"
  type        = string
  default     = ""
  nullable    = false

  validation {
    condition     = can(regex("_CL$", var.table_name))
    error_message = "The table_name must end with '_CL' (e.g., 'MyTable_CL')."
  }
}

variable "columns_template_path" {
  description = "Path to the JSON file containing column definitions"
  type        = string
  default     = ""
}

variable "retention_days" {
  description = "The table's retention in days (30 to 730)"
  type        = number
  default     = -1 # -1:  Uses default retention for the workspace
  nullable    = false

  validation {
    condition     = var.retention_days == -1 || (var.retention_days >= 30 && var.retention_days <= 730)
    error_message = "Retention days must be between 30 and 730."
  }
}

variable "total_retention_in_days" {
  description = "The table's total retention in days (30 to 4383)"
  type        = number
  default     = -1 # -1:  Uses default retention for the workspace
  nullable    = false

  validation {
    condition     = var.total_retention_in_days == -1 || (var.total_retention_in_days >= 30 && var.total_retention_in_days <= 4383)
    error_message = "Total retention days must be between 30 and 4383."
  }
}

variable "dcr_name" {
  description = "Name of the Data Collection Rule"
  type        = string
  default     = ""
  nullable    = false

}