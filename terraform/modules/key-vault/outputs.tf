# =============================================================================
# modules/key-vault/outputs.tf
# =============================================================================

output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Resource ID of the Key Vault. Pass to agent-vm module."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "URI of the Key Vault (https://kv-snowtee-{env}-eus-01.vault.azure.net/)."
}

output "key_vault_name" {
  value       = azurerm_key_vault.this.name
  description = "Name of the Key Vault."
}
