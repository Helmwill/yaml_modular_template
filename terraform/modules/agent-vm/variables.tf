# =============================================================================
# modules/agent-vm/variables.tf
# =============================================================================

variable "env" {
  type        = string
  description = "Environment name: dev, qa, or prod. Drives VM name Agent-tee-{env}-linux-01."

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
  description = "Resource group to deploy the VM into."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the VM NIC. Use agent_subnet_id from the networking module."
}

variable "vm_sku" {
  type        = string
  default     = "Standard_B2s"
  description = "Azure VM SKU for the agent. Standard_B2s (2 vCPU, 4 GB RAM) is sufficient for most build workloads."
}

variable "os_disk_size_gb" {
  type        = number
  default     = 64
  description = "OS disk size in GB."
}

variable "ado_org_url" {
  type        = string
  description = "Azure DevOps organisation URL (e.g. https://dev.azure.com/myorg)."
}

variable "ado_pool_name" {
  type        = string
  description = "Agent pool name to register into. Use pool_name output from agent-pool module."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault resource ID. Used to grant the VM Managed Identity read access to secrets."
}

variable "key_vault_uri" {
  type        = string
  description = "Key Vault URI (https://...). Used to fetch the ADO PAT during cloud-init."
}

variable "acr_id" {
  type        = string
  description = "Container Registry resource ID. Used to grant AcrPull to the VM Managed Identity."
}

variable "admin_username" {
  type        = string
  default     = "azureagent"
  description = "Local administrator username for the VM."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
