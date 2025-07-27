# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-filestorage"
}

variable "location" {
  description = "Azure region"
  default     = "Central US"
}

variable "storage_account_name" {
  description = "Storage account name (must be globally unique)"
  default     = "yourstorageaccount001" # Change this to something unique
}

variable "file_share_name" {
  description = "Name of the file share"
  default     = "myfileshare"
}

variable "vpn_client_address_space" {
  description = "Address space for VPN clients"
  default     = ["172.16.0.0/24"]
}

variable "root_certificate_name" {
  description = "Name of the root certificate"
  default     = "P2SRootCert"
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  default     = "p2s"
}

variable "key_vault_resource_group" {
  description = "Resource group name where Key Vault exists"
  default     = "main"
}

variable "key_vault_secret_name" {
  description = "Name of the Key Vault secret containing certificate data"
  default     = "root-certificate"
}

variable "use_keyvault_certificate" {
  description = "Whether to use certificate from Key Vault or local variable"
  type        = bool
  default     = true
}

variable "local_certificate_data" {
  description = "Base64 encoded certificate data (fallback if Key Vault not accessible)"
  type        = string
  default     = ""
  sensitive   = true
}