locals {
  # Sanitize the runbook name to meet Azure requirements
  sanitized_runbook_name = lower(replace(
    replace(var.runbook_name, "/[^a-zA-Z0-9-]/", "-"),
    "/^-+/", ""
  ))
}

resource "azurerm_automation_runbook" "runbook" {
  name                    = substr(local.sanitized_runbook_name, 0, 63)
  location                = var.location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  runbook_type            = var.runbook_type

  # Use the file path passed from root module
  content      = file(var.script_file_path) # Directly read the file here
  description  = var.description
  log_verbose  = var.log_verbose
  log_progress = var.log_progress
  tags         = var.tags
}

resource "azurerm_automation_schedule" "schedule" {
  name                    = "run_${substr(local.sanitized_runbook_name, 0, 49)}_${var.time_suffix}"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = var.schedule_start_time

  description = "Daily schedule for ${var.runbook_name}"

  lifecycle {
    ignore_changes        = [start_time] # Allow natural schedule progression
    create_before_destroy = true         # Ensure smooth updates
  }

}


resource "azurerm_automation_job_schedule" "job_schedule" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  runbook_name            = azurerm_automation_runbook.runbook.name
  schedule_name           = azurerm_automation_schedule.schedule.name

  run_on = var.hybrid_worker_group != "" ? var.hybrid_worker_group : null
  #run_on = var.hybrid_worker_group

  parameters = {
    azure_tenantid          = var.azure_tenantid
    subscription_name       = var.subscription_name
    resource_group_name     = var.resource_group_name
    key_vault_name          = var.keyvault_name
    dcr_name                = var.dcr_name
    dcr_stream_name         = var.dcr_stream_name
    secret_name_sp_app_id   = var.secret_name_sp_app_id
    secret_name_sp_password = var.secret_name_sp_password
  }
}