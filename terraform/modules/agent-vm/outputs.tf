# =============================================================================
# modules/agent-vm/outputs.tf
# =============================================================================

output "vm_id" {
  value       = azurerm_linux_virtual_machine.agent.id
  description = "Resource ID of the agent VM."
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.agent.name
  description = "VM name (Agent-tee-{env}-linux-01). Must match agentName in pipeline YAML."
}

output "private_ip_address" {
  value       = azurerm_network_interface.agent.private_ip_address
  description = "Private IP address of the agent VM."
}

output "managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.agent.principal_id
  description = "Principal ID of the VM's Managed Identity. Pass to container-registry and key-vault modules for role assignments."
}

output "managed_identity_client_id" {
  value       = azurerm_user_assigned_identity.agent.client_id
  description = "Client ID of the VM's Managed Identity."
}
