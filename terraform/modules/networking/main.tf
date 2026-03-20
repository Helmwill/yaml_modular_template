# =============================================================================
# modules/networking/main.tf
# =============================================================================
# Creates the VNet, agent subnet, and NSG for self-hosted pipeline agent VMs.
#
# NSG rules:
#   - Inbound:  deny all (agents initiate outbound connections to ADO)
#   - Outbound: allow HTTPS (443) to Internet for ADO agent communication
#               allow HTTPS (443) to AzureCloud service tag for ACR / KV
#               deny all other outbound
# =============================================================================

locals {
  name_prefix = "snowtee-${var.env}-eus-01"

  common_tags = merge(var.tags, {
    managed-by  = "terraform"
    environment = var.env
    module      = "networking"
  })
}

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Agent Subnet
# ---------------------------------------------------------------------------

resource "azurerm_subnet" "agents" {
  name                 = "snet-agents-${var.env}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.agent_subnet_cidr]
}

# ---------------------------------------------------------------------------
# Network Security Group
# ---------------------------------------------------------------------------

resource "azurerm_network_security_group" "agents" {
  name                = "nsg-agents-${local.name_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTPS outbound to ADO / Azure services
  security_rule {
    name                       = "AllowHttpsOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  # Allow outbound to Azure cloud services (ACR, Key Vault, Storage)
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  # Deny all other outbound
  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny all inbound (agents initiate outbound; no inbound needed)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "agents" {
  subnet_id                 = azurerm_subnet.agents.id
  network_security_group_id = azurerm_network_security_group.agents.id
}
