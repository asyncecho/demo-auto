output "role_assignment_id" {
  description = "The ID of the role assignment"
  value       = azurerm_role_assignment.dcr_role.id
}

output "service_principal_object_id" {
  description = "The object ID of the service principal that was granted access"
  value       = data.azuread_service_principal.app_sp.object_id
}
