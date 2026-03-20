# =============================================================================
# modules/agent-pool/main.tf
# =============================================================================
# Creates an Azure DevOps self-hosted agent pool and associates it with the
# target project as an agent queue.
#
# Naming convention enforced here to match pipeline YAML variables:
#   Pool-tee-{env}-eus-01
# =============================================================================

locals {
  pool_name = "Pool-tee-${var.env}-eus-01"
}

# Look up the ADO project by name — avoids hardcoding project IDs.
data "azuredevops_project" "this" {
  name = var.ado_project_name
}

# Create the self-hosted agent pool at the organisation level.
resource "azuredevops_agent_pool" "this" {
  name           = local.pool_name
  auto_provision = var.auto_provision_in_all_projects
  auto_update    = true
}

# Associate the pool with the target project as an agent queue.
resource "azuredevops_agent_queue" "this" {
  project_id    = data.azuredevops_project.this.id
  agent_pool_id = azuredevops_agent_pool.this.id
}
