resource_group_name = "rg-filestorage" # Change this to your preferred resource group name
location            = "Central US" # Change this to your preferred Azure region

storage_account_name = "mystorageaccount20250727" # Change this!

file_share_name = "myfileshare" # Change this to your preferred file share name

vpn_client_address_space = ["172.16.0.0/24"] # VPN client address space (should not overlap with your VNet or local network)
