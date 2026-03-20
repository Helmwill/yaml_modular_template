# =============================================================================
# modules/container-registry/outputs.tf
# =============================================================================

output "acr_id" {
  value       = azurerm_container_registry.this.id
  description = "Resource ID of the container registry. Pass to agent-vm and container-app modules."
}

output "login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "Login server URL (e.g. Templatedev.azurecr.io). Matches AcrLoginServer in common.yaml."
}

output "acr_name" {
  value       = azurerm_container_registry.this.name
  description = "Registry name."
}
