# Azure Private File Share with Point-to-Site VPN and DNS Resolver Deployment.
<img width="673" height="302" alt="image" src="https://github.com/user-attachments/assets/057e3558-5c9a-49f0-bc60-aa7499ae4596" />

This guide walks through creating a completely private Azure File Share accessible only through a secure VPN connection with Terraform. In short, my goal was to be able securely connect from my On-Premise Proxmox environment to my Azure environment with VPN and being able to resolve Azure private DNS.  

### Key Components in this Architecture:
1. VNet Structure (10.0.0.0/16):

DNS Subnet (10.0.3.0/24) - Contains DNS Private Resolver
Storage Subnet (10.0.1.0/24) - Contains Private Endpoint
Gateway Subnet (10.0.2.0/24) - Contains VPN Gateway

2. DNS Private Resolver (10.0.3.4):

Inbound endpoint for VPN clients to query
Forwards DNS queries to Azure DNS and Private DNS Zone
Key component that makes domain names work

3. Private Endpoint (10.0.1.4):

Private IP for storage account access
Automatically registered in Private DNS Zone
Direct connection to storage account

4. Private DNS Zone:

Maps domain to private IP: mystorageaccount → 10.0.1.4
Linked to VNet for automatic resolution
Works with DNS Private Resolver

Connection Flow:

Azure AD authentication through VPN
DNS queries go to Private DNS Resolver (10.0.3.4)
Resolver checks Private DNS Zone
Returns private IP (10.0.1.4)
Traffic flows through VPN to Private Endpoint

Security Best Practicies:

Zero public internet exposure
Azure AD authentication
Private DNS resolution
Encrypted VPN tunnel
Network ACLs protection

## Prerequisites

1. **Azure CLI** installed and authenticated (`az login`) assuming you already have necessary permission to create these resources. 
2. **Terraform** installed (version 1.5.5+)

<img width="799" height="164" alt="image" src="https://github.com/user-attachments/assets/f29f0d69-dbb4-417a-bb13-23f17847e891" />

<img width="699" height="464" alt="image" src="https://github.com/user-attachments/assets/531c0e11-8ea8-49ab-bcd0-0b31adbd2fe3" />

## Step-by-Step Deployment

### 1. Prepare the Terraform Files

Create a new directory and save all the Terraform files:
```bash
mkdir azure-private-fileshare
cd azure-private-fileshare
```

Save the provided files:
- `main.tf` (main Terraform configuration)
- `terraform.tfvars` (variables configuration)

### 2. Configure Variables

Edit `terraform.tfvars` file:

```hcl
resource_group_name = "rg-filestorage"
location           = "Central US"

# IMPORTANT: Change this to something globally unique!
storage_account_name = "mystorageaccount20250727"

file_share_name = "myfileshare"
vpn_client_address_space = ["172.16.0.0/24"]

```

### 3. Deploy Infrastructure

Initialize and deploy with Terraform:

```bash
terraform init

terraform plan

terraform apply
```

**Note**: The VPN Gateway creation takes 20-45 minutes. Storage account will have private endpoint created.

### 4. Verify Private Endpoints

After deployment, both services will be accessible only through private endpoints:

```bash
# Check outputs
terraform output

# You should see private IPs for storage account
terraform output storage_account_private_endpoint_ip

**Note**: The VPN Gateway creation takes 20-45 minutes. Be patient!

### 5. Download VPN Client Configuration

After deployment completes:

1. Go to Azure Portal
2. Navigate to your VPN Gateway: `vpn-gateway`
3. Go to **Point-to-site configuration**
4. Click **Download VPN client from Microsoft Store**
5. Extract the ZIP file
6. Import config file to your azure vpn

```
<img width="464" height="268" alt="image" src="https://github.com/user-attachments/assets/94901f74-e975-4774-94e4-a36c5bafa435" />

<img width="461" height="216" alt="image" src="https://github.com/user-attachments/assets/af2ecdfc-f969-4ba5-aaef-e459aff1375d" />

```
### 6. Connect and Test

1. **Connect to VPN**: Use the installed VPN client to connect
2. **Verify connection**: Check that you're connected to the `172.16.0.x` address space
3. **Test DNS resolution**:
   ```cmd
   nslookup yourstorageaccount.privatelink.file.core.windows.net
   Should resolve to a `10.0.1.x` address (private endpoint IP)
   ```
<img width="1911" height="616" alt="image" src="https://github.com/user-attachments/assets/ca769216-dbe4-4da3-b73c-feed6e492fe1" />

<img width="306" height="176" alt="image" src="https://github.com/user-attachments/assets/144e0919-12f1-497a-a785-751374849c59" />

### 7. Mount File Share

Once connected to VPN, mount the file share:

**Command Line:**
```cmd
# Get the storage account key from terraform output
terraform output -raw storage_account_key

# Mount the drive (replace with your storage account name and key)
net use Z: \\yourstorageaccount.privatelink.file.core.windows.net\myfileshare /user:Azure\yourstorageaccount YOUR_STORAGE_KEY /persistent:yes
```
<img width="2384" height="196" alt="image" src="https://github.com/user-attachments/assets/381ec4e2-d738-42e0-9dbb-4b75c294d403" />

## Verification Steps

1. **Check VPN Connection**: Verify you have a 172.16.0.x IP address
2. **DNS Resolution**: Ensure storage account resolves to private IP (10.0.1.x)
3. **File Access**: Create/read files on the Z: drive
4. **Network Traffic**: Confirm traffic goes through private endpoint (not internet)
   
<img width="8322" height="496" alt="image" src="https://github.com/user-attachments/assets/95cd0ff3-cdf6-42eb-8a0b-d43c30366f56" />

## Troubleshooting

### Common Issues:

1. **Storage account name not unique**: Change `storage_account_name` in tfvars
2. **Can't access file share**: Verify VPN connection and DNS resolution
3. **Permission denied**: Check storage account access key is correct

### Useful Commands:

```bash
# Check Terraform outputs
terraform output

# Get storage account key
terraform output -raw storage_account_key

# Destroy infrastructure (when done testing)
terraform destroy
```

## Security Notes

-  Storage account has public access disabled
-  All traffic goes through private endpoint
-  VPN connection is certificate-authenticated
-  DNS resolves to private IP addresses
-  No internet exposure of file share

## Cost Considerations

- **VPN Gateway**: ~$150-200/month (VpnGw1 SKU)
- **Storage Account**: Pay-per-use (very low for testing)
- **Private Endpoint**: ~$7/month
- **Data Transfer**: Minimal for VPN traffic

Consider using **VpnGw1AZ** for production with availability zones, or explore **Virtual WAN** for multiple sites.
