data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

module "automation_runbook" {
  source = "./automatino_runbook"

  automation_account_name = var.automation_account_name
  azure_tenantid          = var.azure_tenant_id
  dcr_name                = var.dcr_name
  dcr_stream_name         = var.dcr_stream_name
  description             = var.description
  hybrid_worker_group     = var.hybrid_worker_group
  keyvault_name           = var.key_vault_name
  location                = var.location
  log_progress            = var.log_progress
  log_verbose             = var.log_verbose
  resource_group_name     = var.resource_group_name
  runbook_name            = var.runbook_name
  runbook_type            = var.runbook_type
  schedule_start_time     = local.schedule_start_time
  script_file_path        = var.script_file_path
  secret_name_sp_app_id   = var.secret_name_sp_app_id
  secret_name_sp_password = var.secret_name_sp_password
  subscription_name       = var.azure_subscription_name
  tags                    = var.tags
  time_suffix             = local.time_suffix
}

module "data_collection_rule" {
  source = "./data_collection_rule"

  columns           = local.columns_definition_dcr
  dcr_name          = var.dcr_name
  dcr_stream_name   = var.dcr_stream_name
  description       = var.description
  destination_name  = var.destination_name
  location          = var.location
  resource_group_id = data.azurerm_resource_group.rg.id
  workspace_id      = data.azurerm_log_analytics_workspace.law.id
}

module "log_analytics_table" {
  source = "./log_analytics_table"

  retention_days       = var.retention_days
  schema_columns       = local.columns_definition_la_table
  table_name           = local.trimmed_table_name
  total_retention_days = var.total_retention_days
  workspace_id         = data.azurerm_log_analytics_workspace.law.id
}

module "rbac_role" {
  source = "./rbac_role"

  application_id       = var.service_principal_client_id
  dcr_id               = module.data_collection_rule.dcr_id
  role_definition_name = var.role_definition_name
}
