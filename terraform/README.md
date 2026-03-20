# Terraform — Snowtee Azure Infrastructure

Modular Terraform for all Azure resources and ADO agent pools used by the pipelines in this repo.

---

## What's Managed

| Resource | Module | Scope |
|---|---|---|
| Resource Groups | `environments/*/main.tf` | Per-environment |
| VNet + Subnet + NSG | `modules/networking` | Per-environment |
| Key Vault | `modules/key-vault` | Per-environment |
| ADO Agent Pool | `modules/agent-pool` | Per-environment |
| Linux Agent VM | `modules/agent-vm` | Per-environment |
| Container Registry (ACR) | `modules/container-registry` | Shared (dev only) |
| Container App + Environment + Log Analytics | `modules/container-app` | Per-environment |
| Remote State Storage | `backend/bootstrap.tf` | Shared (once) |

**Not managed here (configure manually in ADO):** service connections, variable groups, pipeline environments (`snowtee-dev/qa/prod`), container image contents.

---

## Prerequisites

- Terraform >= 1.7.0, Azure CLI >= 2.55.0
- Azure: Contributor + Owner (for RBAC assignments) on the subscription
- ADO: Project Collection Administrator
- Service principal with Workload Identity Federation

---

## Directory Structure

```
terraform/
├── backend/bootstrap.tf          ← One-time: creates remote state storage
├── modules/
│   ├── agent-pool/               ← ADO self-hosted agent pool
│   ├── agent-vm/                 ← Linux VM + cloud-init agent registration
│   ├── networking/               ← VNet, subnet, NSG
│   ├── container-registry/       ← Shared ACR (Templatedev)
│   ├── key-vault/                ← Per-environment Key Vault (RBAC mode)
│   └── container-app/            ← Container App + environment + Log Analytics
└── environments/
    ├── dev/                      ← Also creates the shared ACR
    ├── qa/                       ← References ACR via data source
    └── prod/                     ← References ACR via data source
```

Each `environments/{env}/` is an independent root with its own remote state — a plan in `dev/` cannot touch `prod` state.

---

## Setup

### 1. Bootstrap remote state (once)

```bash
cd terraform/backend && terraform init && terraform apply
```

Creates: `rg-snowtee-tfstate-eus-01`, storage account `stsnowteeTfstate`, containers `tfstate-dev/qa/prod`. Store the resulting `terraform.tfstate` somewhere safe.

### 2. Set environment variables

```bash
export ARM_CLIENT_ID="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_USE_OIDC="true"
export AZDO_ORG_SERVICE_URL="https://dev.azure.com/<your-org>"
export AZDO_PERSONAL_ACCESS_TOKEN="..."
export TF_VAR_tenant_id="$ARM_TENANT_ID"
export TF_VAR_operator_object_ids='["<your-object-id>"]'
```

### 3. Deploy an environment

```bash
cd terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**After first apply:** open Key Vault `kv-snowtee-{env}-eus-01` in the portal and set `ado-pat` to a PAT with **Agent Pools (Read & manage)** scope. The VM fetches this on first boot to register the agent.

### Destroy

```bash
terraform plan -destroy -out=tfplan-destroy && terraform apply tfplan-destroy
```

> **Warning:** The shared ACR lives in the dev resource group — destroying dev breaks qa/prod image pulls. Key Vault is soft-deleted for 90 days.

---

## Module Reference

### `modules/agent-pool`
Creates an ADO self-hosted agent pool + queue.

| Input | Default | Description |
|---|---|---|
| `env` | — | Drives pool name `Pool-tee-{env}-eus-01` |
| `ado_project_name` | — | ADO project name |
| `auto_provision_in_all_projects` | `false` | |

Outputs: `pool_id`, `pool_name` (`Pool-tee-{env}-eus-01`), `queue_id`

---

### `modules/agent-vm`
Linux VM that self-registers as a pipeline agent on first boot via cloud-init.

| Input | Default | Description |
|---|---|---|
| `env` | — | Drives VM name `Agent-tee-{env}-linux-01` |
| `vm_sku` | `Standard_B2s` | VM size |
| `subnet_id` | — | From `networking.agent_subnet_id` |
| `ado_org_url`, `ado_pool_name` | — | ADO registration |
| `key_vault_id`, `key_vault_uri` | — | KV role assignment + cloud-init PAT fetch |
| `acr_id` | — | AcrPull role assignment |

Outputs: `vm_id`, `vm_name`, `managed_identity_principal_id`

---

### `modules/networking`
VNet, agent subnet, NSG. Outbound HTTPS allowed; all inbound denied.

| Input | Description |
|---|---|
| `vnet_address_space` | e.g. `["10.10.0.0/16"]` |
| `agent_subnet_cidr` | e.g. `"10.10.1.0/24"` |

CIDRs by env: dev `10.10.x`, qa `10.20.x`, prod `10.30.x`

Outputs: `vnet_id`, `agent_subnet_id`, `nsg_id`

---

### `modules/container-registry`
Single shared ACR (`Templatedev`). Matches `AcrRegistry` in `pipelines/variables/common.yaml`. Created in dev; qa/prod reference it via data source.

| Input | Default | Description |
|---|---|---|
| `name` | `Templatedev` | Must match pipeline `AcrRegistry` |
| `sku` | `Standard` | |
| `admin_enabled` | `false` | Use Managed Identity instead |
| `acr_pull_principal_ids` | `[]` | Identities granted AcrPull |

Outputs: `acr_id`, `login_server` (`Templatedev.azurecr.io`)

---

### `modules/key-vault`
Per-environment Key Vault (RBAC mode). Creates placeholder secrets — populate values after apply.

| Input | Default | Description |
|---|---|---|
| `env` | — | |
| `soft_delete_retention_days` | `7` | Use `90` for prod |
| `operator_object_ids` | `[]` | Secrets Officer (read+write) |
| `vm_principal_ids` | `[]` | Secrets User (read-only) |

Secrets created (set to `"REPLACE-ME"`): `ado-pat`, `vm-admin-password`

Outputs: `key_vault_id`, `key_vault_uri`

---

### `modules/container-app`
Container App + Container Apps Environment + Log Analytics. Terraform sets `image_tag = "initial"` on first apply; subsequent updates are done by the pipeline. The image field has `lifecycle.ignore_changes` so Terraform never reverts a pipeline-deployed tag.

| Input | Default | Description |
|---|---|---|
| `container_app_name` | — | e.g. `snowtee-dev` — matches `WebAppName` in ADO variable group |
| `acr_login_server` | — | From `container-registry.login_server` |
| `image_name` | `TemplateDevApp` | Matches `ImageName` in `common.yaml` |
| `cpu` / `memory` | `0.5` / `1Gi` | Use `1.0` / `2Gi` for prod |
| `min_replicas` / `max_replicas` | `0` / `3` | Use `1` / `10` for prod |

Outputs: `container_app_name`, `fqdn`

---

## Naming Conventions

| Pipeline Variable | Value | Terraform Resource |
|---|---|---|
| `poolName` | `Pool-tee-{env}-eus-01` | `azuredevops_agent_pool.this.name` |
| `agentName` | `Agent-tee-{env}-linux-01` | `azurerm_linux_virtual_machine.agent.name` |
| `AcrRegistry` | `Templatedev` | `azurerm_container_registry.this.name` |
| `AcrLoginServer` | `Templatedev.azurecr.io` | `azurerm_container_registry.this.login_server` |
| `WebAppName` | `snowtee-{env}` | `azurerm_container_app.this.name` |
| `ResourceGroup` | `rg-snowtee-{env}-eus-01` | `azurerm_resource_group.this.name` |
| `KeyVaultName` | `kv-snowtee-{env}-eus-01` | `azurerm_key_vault.this.name` |

---

## Secrets

Never commit to `.tfvars` or version control: ADO PATs, SP client secrets, tenant/subscription IDs, `operator_object_ids`. Use `TF_VAR_` env vars.

**Runtime flow:**
1. Terraform creates Key Vault with placeholder secrets
2. Operator populates `ado-pat` in Key Vault
3. On first boot, the VM's Managed Identity fetches `ado-pat` and registers the agent
4. Pipeline jobs use ADO variable groups linked to Key Vault for runtime secrets

**PAT rotation:** update `ado-pat` in Key Vault, then either re-run the agent config script on the VM or taint and re-apply: `terraform taint module.agent_vm.azurerm_linux_virtual_machine.agent`

---

## Adding an Environment

1. Copy `environments/dev/` to `environments/{newenv}/`
2. Update `backend.tf`: set `container_name = "tfstate-{newenv}"`
3. Create the blob container in the bootstrap storage account
4. Update `main.tf`: set `env = "{newenv}"` and adjust CIDRs
5. Update `terraform.tfvars` with environment-specific values
6. Create the ADO variable group `{newenv}` linked to the Key Vault
7. `terraform init && terraform plan`

---

## Contributing

- Run `terraform fmt -recursive` before committing
- Run `terraform validate` in each changed environment directory before opening a PR
- Never commit `.terraform/` or `*.tfstate` (`.gitignore` covers these)
- Sensitive values must never appear in commit diffs — use `TF_VAR_` env vars
