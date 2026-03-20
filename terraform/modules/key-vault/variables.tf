# =============================================================================
# modules/key-vault/variables.tf
# =============================================================================

variable "env" {
  type        = string
  description = "Environment name: dev, qa, or prod."

  validation {
    condition     = contains(["dev", "qa", "prod"], var.env)
    error_message = "env must be one of: dev, qa, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the Key Vault into."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID."
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "Key Vault SKU: standard or premium."

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "Soft-delete retention in days. Use 7 for dev/qa, 90 for prod."

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "operator_object_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs (users or service principals) granted Key Vault Secrets Officer role."
}

variable "vm_principal_ids" {
  type        = list(string)
  default     = []
  description = "Managed Identity principal IDs granted Key Vault Secrets User role (read-only)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
