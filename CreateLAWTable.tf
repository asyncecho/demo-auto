data "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  resource_group_name = var.law_resource_group_name
}

locals {
  columns_definition_la_table = [
    for col in jsondecode(file(var.columns_template_path)) : {
      name        = col.name
      type        = col.type
      description = try(col.description, null)
    }
  ]

  #needed for the DCR
  trimmed_table_name = replace(var.table_name, "/_CL$/", "")

  columns_definition_dcr = [
    for col in jsondecode(file(var.columns_template_path)) : {
      name = col.name
      type = col.type
    }
  ]
}

resource "azapi_resource" "la_custom_table" {
  name      = var.table_name
  parent_id = data.azurerm_log_analytics_workspace.law.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = {
    "properties" : {
      "schema" : {
        "name" : var.table_name,
        "columns" : local.columns_definition_la_table
      },
      "retentionInDays" : var.retention_days,
      "totalRetentionInDays" : var.total_retention_in_days
    }
  }
}
