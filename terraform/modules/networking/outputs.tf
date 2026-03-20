# =============================================================================
# modules/networking/outputs.tf
# =============================================================================

output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Resource ID of the virtual network."
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "Name of the virtual network."
}

output "agent_subnet_id" {
  value       = azurerm_subnet.agents.id
  description = "Resource ID of the agent subnet. Pass to the agent-vm module."
}

output "nsg_id" {
  value       = azurerm_network_security_group.agents.id
  description = "Resource ID of the agent NSG."
}
