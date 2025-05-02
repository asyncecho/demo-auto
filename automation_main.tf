locals {
  # Stable reference that only changes when the time changes
  time_suffix = replace(var.start_time_utc, ":", "-") # "09:00:00" → "09-00-00"

  # Actual schedule start time (tomorrow)
  schedule_start_time = format(
    "%sT%sZ",
    formatdate("YYYY-MM-DD", timeadd(timestamp(), "24h")),
    var.start_time_utc
  )
}

module "automation_runbook" {
  source = "./modules/automation_runbook"

  runbook_name            = var.runbook_name
  azure_tenantid          = var.azure_tenantid
  subscription_name       = var.subscription_name
  resource_group_name     = var.resource_group_name
  automation_account_name = var.automation_account_name
  script_file_path        = "${path.root}/${trimprefix(var.script_file_path, "./")}"

  schedule_start_time = local.schedule_start_time # For actual schedule
  time_suffix         = local.time_suffix         # For change detection

  location            = var.location
  description         = var.runbook_description
  log_verbose         = true
  log_progress        = true
  hybrid_worker_group = var.hybrid_worker_group
  runbook_type        = var.runbook_type
  keyvault_name       = var.keyvault_name

  secret_name_sp_app_id   = var.secret_name_sp_app_id
  secret_name_sp_password = var.secret_name_sp_password


  # Parameters to be passed to the runbook
  dcr_name        = var.dcr_name
  dcr_stream_name = var.dcr_stream_name

  tags = {
    Environment   = "POC"
    ApplicationId = "POC"
    ManagedBy     = "Terraform"
    owner         = "A. Kalinin"
  }

}