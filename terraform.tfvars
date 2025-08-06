resource_group_name = "rg-vpn-fileshare-demo"
location            = "Central US"
storage_account_name = "sahibdemo12345"
vpn_client_address_space = ["172.16.0.0/24"] #VPN client address space (should not overlap with your VNet or local network)
