# =============================================================================
# environments/dev/backend.tf
# =============================================================================
# Remote state stored in Azure Blob Storage.
# Run bootstrap.tf once before terraform init to create the storage account.
#
# To initialise:
#   terraform init \
#     -backend-config="storage_account_name=stsnowteeTfstate" \
#     -backend-config="resource_group_name=rg-snowtee-tfstate-eus-01"
# =============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-snowtee-tfstate-eus-01"
    storage_account_name = "stsnowteeTfstate"
    container_name       = "tfstate-dev"
    key                  = "snowtee.tfstate"
    use_oidc             = true
  }
}
