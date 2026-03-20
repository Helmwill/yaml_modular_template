# =============================================================================
# modules/container-app/variables.tf
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
  description = "Resource group to deploy the Container App into."
}

variable "container_app_name" {
  type        = string
  description = "Name of the Azure Container App (e.g. snowtee-dev). Exposed as WebAppName in pipeline variable group."
}

variable "acr_login_server" {
  type        = string
  description = "ACR login server URL (e.g. Templatedev.azurecr.io). Matches AcrLoginServer in common.yaml."
}

variable "image_name" {
  type        = string
  default     = "TemplateDevApp"
  description = "Container image name. Matches ImageName in common.yaml."
}

variable "image_tag" {
  type        = string
  default     = "initial"
  description = "Initial image tag. The pipeline (az containerapp update) owns tag updates — do not change this after first apply."
}

variable "target_port" {
  type        = number
  default     = 80
  description = "Port the container listens on."
}

variable "ingress_type" {
  type        = string
  default     = "external"
  description = "Ingress type: external (public) or internal."

  validation {
    condition     = contains(["external", "internal"], var.ingress_type)
    error_message = "ingress_type must be external or internal."
  }
}

variable "cpu" {
  type        = number
  default     = 0.5
  description = "CPU allocation per replica (cores). 0.5 for dev/qa, 1.0 for prod."
}

variable "memory" {
  type        = string
  default     = "1Gi"
  description = "Memory allocation per replica. 1Gi for dev/qa, 2Gi for prod."
}

variable "min_replicas" {
  type        = number
  default     = 0
  description = "Minimum replicas. 0 allows scale-to-zero (dev/qa). Use 1+ for prod."
}

variable "max_replicas" {
  type        = number
  default     = 3
  description = "Maximum replicas."
}

variable "acr_id" {
  type        = string
  description = "ACR resource ID for granting AcrPull to the Container App system identity."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags."
}
