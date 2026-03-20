# =============================================================================
# modules/agent-vm/main.tf
# =============================================================================
# Linux VM that runs as a self-hosted Azure DevOps pipeline agent.
#
# Naming: Agent-tee-{env}-linux-01 — matches agentName in pipeline variables.
#
# On first boot, cloud-init:
#   1. Installs Docker, Azure CLI, and Trivy (version pinned to match common.yaml)
#   2. Downloads the Azure Pipelines agent tarball
#   3. Fetches the ADO PAT from Key Vault via the VM's Managed Identity
#   4. Registers and starts the agent as a systemd service
#
# The VM uses a User-Assigned Managed Identity so that:
#   - ACR pulls do not require stored credentials
#   - Key Vault secret reads do not require stored credentials
#   - The identity can be referenced before the VM is created (chicken-and-egg safe)
# =============================================================================

locals {
  vm_name     = "Agent-tee-${var.env}-linux-01"
  nic_name    = "nic-agent-${var.env}-eus-01"
  identity_name = "id-agent-${var.env}-eus-01"

  common_tags = merge(var.tags, {
    managed-by  = "terraform"
    environment = var.env
    module      = "agent-vm"
    role        = "ado-agent"
  })

  # cloud-init script: install dependencies, register the ADO agent.
  # The ADO PAT is fetched at runtime from Key Vault using the VM's Managed Identity.
  cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: false

    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - jq
      - unzip
      - git

    runcmd:
      # --- Docker ---
      - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      - echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
      - apt-get update -y
      - apt-get install -y docker-ce docker-ce-cli containerd.io
      - usermod -aG docker ${var.admin_username}
      - systemctl enable docker
      - systemctl start docker

      # --- Azure CLI ---
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash

      # --- Trivy (version matches common.yaml TrivyVersion: 0.48.0) ---
      - curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.48.0

      # --- Azure Pipelines Agent ---
      - mkdir -p /opt/azagent
      - cd /opt/azagent
      - ADP_VERSION=$(curl -s https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest | jq -r '.tag_name' | sed 's/v//')
      - curl -O "https://vstsagentpackage.blob.core.windows.net/agent/$${ADP_VERSION}/vsts-agent-linux-x64-$${ADP_VERSION}.tar.gz"
      - tar zxvf vsts-agent-linux-x64-$${ADP_VERSION}.tar.gz
      - chown -R ${var.admin_username}:${var.admin_username} /opt/azagent

      # --- Fetch ADO PAT from Key Vault using Managed Identity ---
      - ACCESS_TOKEN=$(curl -s "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net" -H "Metadata:true" | jq -r '.access_token')
      - ADO_PAT=$(curl -s "${var.key_vault_uri}secrets/ado-pat?api-version=7.0" -H "Authorization:Bearer $${ACCESS_TOKEN}" | jq -r '.value')

      # --- Configure and start the agent ---
      - sudo -u ${var.admin_username} /opt/azagent/config.sh --unattended --url "${var.ado_org_url}" --auth pat --token "$${ADO_PAT}" --pool "${var.ado_pool_name}" --agent "${local.vm_name}" --acceptTeeEula
      - /opt/azagent/svc.sh install ${var.admin_username}
      - /opt/azagent/svc.sh start
  CLOUDINIT
}

# ---------------------------------------------------------------------------
# User-Assigned Managed Identity
# ---------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "agent" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Role Assignments for the Managed Identity
# ---------------------------------------------------------------------------

# AcrPull — allows the agent VM to pull images from ACR without stored credentials
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.agent.principal_id
}

# Key Vault Secrets User — allows the agent VM to read secrets (ADO PAT, etc.)
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agent.principal_id
}

# ---------------------------------------------------------------------------
# Network Interface
# ---------------------------------------------------------------------------

resource "azurerm_network_interface" "agent" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Linux Virtual Machine
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "agent" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_sku
  admin_username      = var.admin_username

  # Disable password auth — SSH key or Managed Identity is used
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.agent.id]

  # User-Assigned Managed Identity for ACR + Key Vault access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agent.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  # Ubuntu 22.04 LTS — matches typical ADO hosted agent base image
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # SSH public key — the private key must be managed outside Terraform
  # (e.g. stored in Key Vault by the operator, or an existing key pair)
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # cloud-init runs on first boot to install and register the agent
  custom_data = base64encode(local.cloud_init)

  tags = local.common_tags

  depends_on = [
    azurerm_role_assignment.kv_secrets_user,
    azurerm_role_assignment.acr_pull,
  ]
}
