# =============================================================================
# environments/qa/main.tf
# =============================================================================
# QA environment. References the shared ACR from dev via a data source.
# Agent pool, VM, Key Vault, networking, and Container App are environment-specific.
# =============================================================================

locals {
  env         = "qa"
  name_suffix = "snowtee-${local.env}-eus-01"

  common_tags = {
    environment = local.env
    project     = "snowtee"
    managed-by  = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# Reference the shared ACR (created in environments/dev)
# ---------------------------------------------------------------------------

data "azurerm_container_registry" "shared" {
  name                = "Templatedev"
  resource_group_name = var.acr_resource_group_name
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  env                 = local.env
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_address_space  = ["10.20.0.0/16"]
  agent_subnet_cidr   = "10.20.1.0/24"
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------

module "key_vault" {
  source = "../../modules/key-vault"

  env                        = local.env
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = 7
  operator_object_ids        = var.operator_object_ids
  tags                       = local.common_tags
}

# ---------------------------------------------------------------------------
# Agent Pool
# ---------------------------------------------------------------------------

module "agent_pool" {
  source = "../../modules/agent-pool"

  env              = local.env
  ado_project_name = var.ado_project_name
}

# ---------------------------------------------------------------------------
# Agent VM
# ---------------------------------------------------------------------------

module "agent_vm" {
  source = "../../modules/agent-vm"

  env                 = local.env
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.networking.agent_subnet_id
  vm_sku              = var.vm_sku
  ado_org_url         = var.ado_org_url
  ado_pool_name       = module.agent_pool.pool_name
  key_vault_id        = module.key_vault.key_vault_id
  key_vault_uri       = module.key_vault.key_vault_uri
  acr_id              = data.azurerm_container_registry.shared.id
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# AcrPull for the QA agent VM on the shared ACR
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "qa_agent_acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = module.agent_vm.managed_identity_principal_id
}

# ---------------------------------------------------------------------------
# Container App
# ---------------------------------------------------------------------------

module "container_app" {
  source = "../../modules/container-app"

  env                 = local.env
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  container_app_name  = "snowtee-${local.env}"
  acr_login_server    = data.azurerm_container_registry.shared.login_server
  image_name          = "TemplateDevApp"
  image_tag           = "initial"
  cpu                 = 0.5
  memory              = "1Gi"
  min_replicas        = 0
  max_replicas        = 3
  target_port         = 80
  ingress_type        = "external"
  acr_id              = data.azurerm_container_registry.shared.id
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "agent_pool_name" {
  value = module.agent_pool.pool_name
}

output "container_app_fqdn" {
  value = module.container_app.fqdn
}

output "key_vault_uri" {
  value = module.key_vault.key_vault_uri
}
