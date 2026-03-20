# =============================================================================
# environments/prod/backend.tf
# =============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-snowtee-tfstate-eus-01"
    storage_account_name = "stsnowteeTfstate"
    container_name       = "tfstate-prod"
    key                  = "snowtee.tfstate"
    use_oidc             = true
  }
}
