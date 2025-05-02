# Get the application directly by its ID
data "azuread_service_principal" "app_sp" {
  client_id = var.application_id
}

# Assign the "Monitoring Metrics Publisher" role to the application on the DCR
resource "azurerm_role_assignment" "dcr_role" {
  scope                = var.dcr_resource.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = data.azuread_service_principal.app_sp.object_id
}

