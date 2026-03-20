# =============================================================================
# modules/container-app/main.tf
# =============================================================================
# Per-environment Azure Container App, Container Apps Environment, and
# Log Analytics workspace.
#
# IMPORTANT — image tag lifecycle:
#   Terraform provisions the app with image_tag = "initial" on first apply.
#   All subsequent image tag updates are performed by the pipeline via:
#     az containerapp update --image <acr>/<image>:<buildId>
#   The `image` block uses lifecycle.ignore_changes so Terraform does not
#   revert the pipeline's tag on the next plan/apply.
# =============================================================================

locals {
  name_suffix = "snowtee-${var.env}-eus-01"

  common_tags = merge(var.tags, {
    managed-by  = "terraform"
    environment = var.env
    module      = "container-app"
  })
}

# ---------------------------------------------------------------------------
# Log Analytics Workspace (required by Container Apps Environment)
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.env == "prod" ? 90 : 30

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Container Apps Environment
# ---------------------------------------------------------------------------

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-${local.name_suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Container App
# ---------------------------------------------------------------------------

resource "azurerm_container_app" "this" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  # System-assigned identity for ACR pulls without stored credentials
  identity {
    type = "SystemAssigned"
  }

  # ACR credentials via Managed Identity (no stored password)
  registry {
    server   = var.acr_login_server
    identity = "system"
  }

  template {
    container {
      name   = var.container_app_name
      image  = "${var.acr_login_server}/${var.image_name}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    external_enabled = var.ingress_type == "external"
    target_port      = var.target_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.common_tags

  lifecycle {
    # The pipeline owns the running image tag. Ignore it here so terraform apply
    # after a pipeline deployment does not revert the tag back to "initial".
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}

# ---------------------------------------------------------------------------
# AcrPull for the Container App's System-Assigned Identity
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.this.identity[0].principal_id
}
