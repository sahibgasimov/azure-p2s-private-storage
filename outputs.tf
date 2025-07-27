# Output values
output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_account_private_endpoint_ip" {
  value = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "file_share_name" {
  value = azurerm_storage_share.main.name
}

output "vpn_gateway_public_ip" {
  value = azurerm_public_ip.vpn_gateway.ip_address
}

output "storage_account_key" {
  value     = azurerm_storage_account.main.primary_access_key
  sensitive = true
}

output "file_share_url" {
  value = "\\\\${azurerm_storage_account.main.name}.privatelink.file.core.windows.net\\${azurerm_storage_share.main.name}"
}

output "azure_ad_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

# Output instructions for next steps
output "next_steps" {
  value = <<-EOT
    Next steps for Azure AD Authentication:
    1. Download Azure VPN Client from Microsoft Store or https://aka.ms/azvpnclientdownload
    2. Sign in with your Azure AD credentials when connecting
    3. Mount file share using the private endpoint URL
        
    Storage will be accessible privately at: ${azurerm_storage_account.main.name}.privatelink.file.core.windows.net
    Private endpoint IP: ${azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address}
    
    Commands for local machine after VPN connection:
    - Mount drive: net use Z: \\${azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address}\${azurerm_storage_share.main.name} /user:Azure\${azurerm_storage_account.main.name} YOUR_STORAGE_KEY
  EOT
}