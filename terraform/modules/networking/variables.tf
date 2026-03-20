# =============================================================================
# modules/networking/variables.tf
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
  description = "Azure region (e.g. eastus)."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy networking resources into."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network (e.g. [\"10.10.0.0/16\"])."
}

variable "agent_subnet_cidr" {
  type        = string
  description = "CIDR block for the agent VM subnet (e.g. \"10.10.1.0/24\")."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to apply to all networking resources."
}
