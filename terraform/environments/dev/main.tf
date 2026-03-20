# =============================================================================
# environments/dev/main.tf
# =============================================================================
# Wires together all modules for the dev environment.
# Resource group, networking, Key Vault, and agent infrastructure are created
# here. The shared ACR is also provisioned from dev and referenced by qa/prod
# via data sources in their respective environment roots.
# =============================================================================

locals {
  env         = "dev"
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
# Networking
# ---------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  env                 = local.env
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_address_space  = ["10.10.0.0/16"]
  agent_subnet_cidr   = "10.10.1.0/24"
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Key Vault (created before the VM so the PAT placeholder exists)
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
# Azure Container Registry (shared; qa/prod use a data source to reference it)
# ---------------------------------------------------------------------------

module "container_registry" {
  source = "../../modules/container-registry"

  name                = "Templatedev"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Agent Pool (Azure DevOps)
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
  acr_id              = module.container_registry.acr_id
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Grant the agent VM's Managed Identity AcrPull on the shared ACR
# (wired through the container-registry module's acr_pull_principal_ids)
# ---------------------------------------------------------------------------

module "container_registry_pull_grants" {
  source = "../../modules/container-registry"

  name                   = "Templatedev"
  location               = var.location
  resource_group_name    = azurerm_resource_group.this.name
  sku                    = "Standard"
  admin_enabled          = false
  acr_pull_principal_ids = [module.agent_vm.managed_identity_principal_id]
  tags                   = local.common_tags

  depends_on = [module.container_registry]
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
  acr_login_server    = module.container_registry.login_server
  image_name          = "TemplateDevApp"
  image_tag           = "initial"
  cpu                 = 0.5
  memory              = "1Gi"
  min_replicas        = 0
  max_replicas        = 3
  target_port         = 80
  ingress_type        = "external"
  acr_id              = module.container_registry.acr_id
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "Resource group name. Set as ResourceGroup in the ADO variable group."
}

output "acr_login_server" {
  value       = module.container_registry.login_server
  description = "ACR login server. Must match AcrLoginServer in common.yaml."
}

output "agent_pool_name" {
  value       = module.agent_pool.pool_name
  description = "Agent pool name. Must match poolName in pipelines/variables/dev.yaml."
}

output "container_app_fqdn" {
  value       = module.container_app.fqdn
  description = "Container App FQDN for health checks and pipeline deploy validation."
}

output "key_vault_uri" {
  value       = module.key_vault.key_vault_uri
  description = "Key Vault URI. Set as KeyVaultName in the ADO variable group."
}
