provider "azurerm" {

  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  required_version = "~> 1.5.5"
}


data "azurerm_client_config" "current" {}


# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-filestorage"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# subnet for storage private endpoint
resource "azurerm_subnet" "storage" {
  name                 = "subnet-storage"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

# Gateway Subnet for VPN Gateway
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}


# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false
 
  large_file_share_enabled = false

  tags = {
    owner = "sahib"
    purpose     = "private-file-storage"
  }
}

resource "azurerm_storage_share" "main" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.main.name
  quota                = 1
}

# Network rules to secure storage account after private endpoint is created
resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id = azurerm_storage_account.main.id

  default_action = "Deny"
  bypass         = ["AzureServices"]

  # Allow access from VNet subnets
  virtual_network_subnet_ids = [
    azurerm_subnet.storage.id,
    azurerm_subnet.gateway.id
  ]

  depends_on = [
    azurerm_private_endpoint.storage,
  ]
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Link Private DNS Zone to VNet (Storage)
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "dns-link-storage"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.storage.id

  private_service_connection {
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# VPN Gateway with Azure AD Authentication
resource "azurerm_virtual_network_gateway" "main" {
  name                = "vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type       = "Vpn"
  vpn_type   = "RouteBased"
  generation = "Generation1"
  sku        = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  vpn_client_configuration {
    address_space = var.vpn_client_address_space

    # Use OpenVPN with Azure AD Authentication
    #https://learn.microsoft.com/en-us/answers/questions/1195225/azure-p2s-vpn-connection-through-azure-vpn-client
    vpn_client_protocols = ["OpenVPN"]
    vpn_auth_types       = ["AAD"]

   
    aad_tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4" # Azure VPN Client App ID
    aad_issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
  }

  depends_on = [azurerm_public_ip.vpn_gateway]
}

