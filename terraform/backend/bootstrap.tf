# =============================================================================
# backend/bootstrap.tf
# =============================================================================
# One-time bootstrap: creates the Azure Storage Account and blob containers
# used as the Terraform remote backend for each environment.
#
# Run once per organisation before any `terraform init` in environments/:
#
#   cd terraform/backend
#   terraform init
#   terraform plan
#   terraform apply
#
# This configuration intentionally uses local state (no backend block) so it
# can be applied before the remote backend exists. Check the resulting
# terraform.tfstate into version control or store it somewhere safe.
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for the state storage account."
}

variable "storage_account_name" {
  type        = string
  default     = "stsnowteeTfstate"
  description = "Globally unique storage account name for Terraform state."
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-snowtee-tfstate-eus-01"
  location = var.location

  tags = {
    managed-by  = "terraform"
    purpose     = "terraform-state"
    environment = "shared"
  }
}

# ---------------------------------------------------------------------------
# Storage Account
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"  # Zone-redundant for all envs

  # Harden the storage account
  allow_nested_items_to_be_public  = false
  shared_access_key_enabled        = true   # needed for terraform backend auth
  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 30  # Recover accidentally deleted state blobs
    }
    versioning_enabled = true  # Keep full state history
  }

  tags = {
    managed-by  = "terraform"
    purpose     = "terraform-state"
    environment = "shared"
  }
}

# ---------------------------------------------------------------------------
# Blob Containers — one per environment
# ---------------------------------------------------------------------------

resource "azurerm_storage_container" "tfstate_dev" {
  name                  = "tfstate-dev"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tfstate_qa" {
  name                  = "tfstate-qa"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "tfstate_prod" {
  name                  = "tfstate-prod"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Storage account name to use in each environment's backend.tf"
}

output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "Resource group containing the state storage account."
}
