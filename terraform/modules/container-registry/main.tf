# =============================================================================
# modules/container-registry/main.tf
# =============================================================================
# Single shared Azure Container Registry (ACR) named "Templatedev".
# Matches AcrRegistry variable in pipelines/variables/common.yaml.
#
# ACR is created once (from environments/dev) and referenced by
# qa/prod via a data source. Managed Identity is used for pulls —
# admin account is disabled.
# =============================================================================

locals {
  common_tags = merge(var.tags, {
    managed-by = "terraform"
    module     = "container-registry"
    shared     = "true"
  })
}

resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# AcrPull role assignments for all provided principal IDs.
# Covers: agent VM Managed Identities and Container App system identities.
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "acr_pull" {
  for_each = toset(var.acr_pull_principal_ids)

  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = each.value
}
