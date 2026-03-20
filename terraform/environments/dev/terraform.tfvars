# =============================================================================
# environments/dev/terraform.tfvars
# =============================================================================
# Non-secret overrides for the dev environment.
# Secrets (tenant_id, operator_object_ids) are injected as TF_VAR_ env vars
# from the Azure DevOps variable group — never stored here.
# =============================================================================

location         = "eastus"
ado_project_name = "snowtee"        # Replace with your ADO project name
ado_org_url      = "https://dev.azure.com/myorg"  # Replace with your ADO org URL
vm_sku           = "Standard_B2s"
