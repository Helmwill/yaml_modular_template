# =============================================================================
# environments/dev/providers.tf
# =============================================================================
# Authentication uses Workload Identity Federation (OIDC) — no stored secrets.
#
# Required environment variables (set in the pipeline step or locally):
#   ARM_CLIENT_ID           - Service principal client ID
#   ARM_TENANT_ID           - Azure AD tenant ID
#   ARM_SUBSCRIPTION_ID     - Target Azure subscription ID
#   ARM_USE_OIDC            - "true"
#   AZDO_ORG_SERVICE_URL    - e.g. https://dev.azure.com/myorg
#   AZDO_PERSONAL_ACCESS_TOKEN - PAT with agent pool + project read/write
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuredevops" {
  # Configured via AZDO_ORG_SERVICE_URL and AZDO_PERSONAL_ACCESS_TOKEN env vars.
}

provider "random" {}
