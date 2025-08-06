resource "azurerm_private_dns_resolver" "main" {
  name                = "dns-resolver"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  virtual_network_id  = azurerm_virtual_network.main.id

  depends_on = [
    azurerm_virtual_network.main,
    azurerm_virtual_network_gateway.main,
    azurerm_subnet.dns
  ]
}

# Inbound endpoint for VPN clients to query
resource "azurerm_private_dns_resolver_inbound_endpoint" "main" {
  name                    = "inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  location                = azurerm_resource_group.main.location
  
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                   = azurerm_subnet.dns.id
  }
}

# dedicated subnet for DNS resolver
resource "azurerm_subnet" "dns" {
  name                 = "subnet-dns"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
    timeouts {
    create = "60m"
    delete = "60m"
  }
    depends_on = [azurerm_virtual_network_gateway.main]

}

