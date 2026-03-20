# =============================================================================
# modules/agent-pool/variables.tf
# =============================================================================

variable "env" {
  type        = string
  description = "Environment name: dev, qa, or prod. Used to construct pool name Pool-tee-{env}-eus-01."

  validation {
    condition     = contains(["dev", "qa", "prod"], var.env)
    error_message = "env must be one of: dev, qa, prod."
  }
}

variable "ado_project_name" {
  type        = string
  description = "Name of the Azure DevOps project to associate the agent queue with."
}

variable "auto_provision_in_all_projects" {
  type        = bool
  default     = false
  description = "Whether to auto-provision the pool into all ADO projects in the organisation."
}
