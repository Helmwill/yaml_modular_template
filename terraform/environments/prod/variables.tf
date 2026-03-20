# =============================================================================
# environments/prod/variables.tf
# =============================================================================

variable "location" {
  type    = string
  default = "eastus"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID. Injected as TF_VAR_tenant_id."
}

variable "ado_project_name" {
  type        = string
  description = "Azure DevOps project name."
}

variable "ado_org_url" {
  type        = string
  description = "Azure DevOps organisation URL."
}

variable "operator_object_ids" {
  type    = list(string)
  default = []
}

variable "vm_sku" {
  type    = string
  default = "Standard_D2s_v3"  # Larger default for prod workloads
}

variable "acr_resource_group_name" {
  type        = string
  description = "Resource group where the shared ACR lives (dev resource group)."
}
