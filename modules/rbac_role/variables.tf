variable "dcr_resource" {
  description = "The azapi_resource representing the Data Collection Rule"
  type = object({
    id = string
  })
}

variable "resource_group_name" {
  description = "Name of the resource group (only needed if using display_name for app lookup)"
  type        = string
  default     = null
}

variable "application_id" {
  description = "The Application ID (Client ID) of the Azure AD application"
  type        = string
}
