# =============================================================================
# environments/dev/variables.tf
# =============================================================================

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region. Matches -eus- in all resource names."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID. Injected as TF_VAR_tenant_id env var."
}

variable "ado_project_name" {
  type        = string
  description = "Azure DevOps project name containing the pipeline."
}

variable "ado_org_url" {
  type        = string
  description = "Azure DevOps organisation URL (e.g. https://dev.azure.com/myorg)."
}

variable "operator_object_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs of humans/SPs that need Key Vault Secrets Officer access."
}

variable "vm_sku" {
  type        = string
  default     = "Standard_B2s"
  description = "VM SKU for the agent. Override in terraform.tfvars if a larger size is needed."
}
