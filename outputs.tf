
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_key" {
  description = "The primary key of the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive = true
}

output "file_share_name" {
  description = "The name of the file share"
  value       = var.file_share_name
}

output "private_endpoint_ip" {
  description = "The private IP address of the storage account private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "vpn_gateway_public_ip" {
  description = "The public IP address of the VPN gateway"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

output "vpn_gateway_id" {
  description = "The ID of the VPN gateway"
  value       = azurerm_virtual_network_gateway.main.id
}

