data "azurerm_resource_group" "law_rg" {
  name = data.azurerm_log_analytics_workspace.law.resource_group_name
}

# Create Data Collection Rule
resource "azapi_resource" "custom_table_dcr" {
  type      = "Microsoft.Insights/dataCollectionRules@2023-03-11"
  name      = var.dcr_name
  parent_id = data.azurerm_resource_group.law_rg.id

  body = {
    location = var.location
    kind     = "Direct"
    properties = {
      description = "A Direct Ingestion Rule with builtin ingestion fqdns"
      "streamDeclarations" : {
        "Custom-${local.trimmed_table_name}" : {
          "columns" : local.columns_definition_dcr
        }
      }
      destinations = {
        logAnalytics = [
          {
            workspaceResourceId = data.azurerm_log_analytics_workspace.law.id
            name                = "la-${data.azurerm_log_analytics_workspace.law.name}"
          }
        ]
      }
      dataFlows = [
        {
          streams      = ["Custom-${local.trimmed_table_name}"]
          destinations = ["la-${data.azurerm_log_analytics_workspace.law.name}"]
          transformKql = "source"
          outputStream = "Custom-${var.table_name}"
        }
      ]
    }
  }

  depends_on = [azapi_resource.la_custom_table]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

module "dcr_role_assignment" {
  source = "./modules/rbac_role"

  dcr_resource   = azapi_resource.custom_table_dcr
  application_id = var.application_id # Application ID of the Entra ID App
}

# Associate DCR with workspace
resource "azurerm_monitor_data_collection_rule_association" "dcr_la_association" {
  name                    = "dcr-to-la-association"
  target_resource_id      = data.azurerm_log_analytics_workspace.law.id
  data_collection_rule_id = azapi_resource.custom_table_dcr.id
  description             = "Association between DCR and a Log Analytics workspace"
}
