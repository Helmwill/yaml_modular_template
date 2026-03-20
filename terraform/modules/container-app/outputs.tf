# =============================================================================
# modules/container-app/outputs.tf
# =============================================================================

output "container_app_id" {
  value       = azurerm_container_app.this.id
  description = "Resource ID of the Container App."
}

output "container_app_name" {
  value       = azurerm_container_app.this.name
  description = "Container App name. Matches WebAppName expected by pipeline variable group."
}

output "fqdn" {
  value       = azurerm_container_app.this.ingress[0].fqdn
  description = "Fully qualified domain name of the Container App ingress endpoint."
}

output "system_identity_principal_id" {
  value       = azurerm_container_app.this.identity[0].principal_id
  description = "Principal ID of the Container App's System-Assigned Managed Identity."
}
