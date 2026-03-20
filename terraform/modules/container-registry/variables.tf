# =============================================================================
# modules/container-registry/variables.tf
# =============================================================================

variable "name" {
  type        = string
  default     = "Templatedev"
  description = "ACR name. Must match AcrRegistry in pipelines/variables/common.yaml."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the registry into."
}

variable "sku" {
  type        = string
  default     = "Standard"
  description = "ACR SKU: Basic, Standard, or Premium."

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  type        = bool
  default     = false
  description = "Enable ACR admin account. Keep false — Managed Identity is used for pulls."
}

variable "acr_pull_principal_ids" {
  type        = list(string)
  default     = []
  description = "Principal IDs (VM Managed Identities, Container App identities) granted AcrPull."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
