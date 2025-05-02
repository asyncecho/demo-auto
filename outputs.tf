
output "log_analytics_table_details" {
  description = "Details about the created Log Analytics table"
  value = {
    name         = var.table_name
    workspace_id = data.azurerm_log_analytics_workspace.law.id
  }
}
