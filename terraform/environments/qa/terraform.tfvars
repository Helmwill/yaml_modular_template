# =============================================================================
# environments/qa/terraform.tfvars
# =============================================================================

location                = "eastus"
ado_project_name        = "snowtee"
ado_org_url             = "https://dev.azure.com/myorg"
vm_sku                  = "Standard_B2s"
acr_resource_group_name = "rg-snowtee-dev-eus-01"   # ACR lives in dev RG
