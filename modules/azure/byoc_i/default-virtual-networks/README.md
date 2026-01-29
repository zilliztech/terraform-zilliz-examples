# Azure Virtual Network Module

This Terraform module creates an Azure Virtual Network (VNet) with subnets, network security groups, and optional NAT Gateway for Zilliz BYOC deployments.

## Features

- Creates a Virtual Network with configurable CIDR block
- Automatically creates two subnets:
  - `milvus` subnet: Uses half of the VNet CIDR (e.g., 10.0.0.0/17 from 10.0.0.0/16)
  - `privatelink` subnet: Fixed at /24 (e.g., 10.0.250.0/24)
- Network Security Group with rules for:
  - VNet internal traffic (inbound and outbound)
  - HTTPS outbound to internet
- Optional NAT Gateway for outbound internet connectivity
- Service endpoints enabled for Microsoft.Storage
- Private endpoint and private link service network policies enabled

## Resources Created

- `azurerm_virtual_network` - The virtual network
- `azurerm_subnet` (milvus) - Subnet for Milvus workloads
- `azurerm_subnet` (privatelink) - Subnet for private endpoints
- `azurerm_network_security_group` - Network security group with default rules
- `azurerm_subnet_network_security_group_association` (2) - Associates NSG with subnets
- `azurerm_nat_gateway` (optional) - NAT Gateway for outbound connectivity
- `azurerm_public_ip` (optional) - Public IP for NAT Gateway
- `azurerm_nat_gateway_public_ip_association` (optional) - Associates Public IP with NAT Gateway
- `azurerm_subnet_nat_gateway_association` (optional) - Associates NAT Gateway with milvus subnet

## Usage

```hcl
module "vnet" {
  source = "../../modules/azure/standard-virtual-networks"

  vnet_name           = "zilliz-byoc-vnet"
  location            = "East US"
  resource_group_name = "rg-zilliz-byoc"
  vnet_cidr          = "10.0.0.0/16"

  # Optional: Create NAT Gateway
  create_nat_gateway = true
  nat_gateway_name   = "zilliz-byoc-nat"

  custom_tags = {
    Environment = "Production"
    Project     = "Zilliz-BYOC"
  }
}
```

## Subnet Configuration

The module automatically creates two subnets:

1. **milvus subnet**: 
   - Name: `milvus`
   - CIDR: Automatically calculated as half of VNet CIDR (e.g., 10.0.0.0/17 from 10.0.0.0/16)
   - Service endpoints: Microsoft.Storage
   - NAT Gateway association: If `create_nat_gateway` is true

2. **privatelink subnet**:
   - Name: `privatelink`
   - CIDR: Fixed at `{first_octet}.{second_octet}.250.0/24` (e.g., 10.0.250.0/24)
   - Service endpoints: Microsoft.Storage

## Network Security Group Rules

The module creates a Network Security Group with the following rules:

| Rule Name | Direction | Priority | Protocol | Source | Destination | Port | Access |
|-----------|-----------|----------|----------|--------|--------------|------|--------|
| AllowVNetInBound | Inbound | 1000 | * | VNet CIDR | VNet CIDR | * | Allow |
| AllowVNetOutBound | Outbound | 1000 | * | VNet CIDR | VNet CIDR | * | Allow |
| AllowHTTPSOutBound | Outbound | 1100 | TCP | * | * | 443 | Allow |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region where the virtual network will be created | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| vnet_cidr | CIDR block for the virtual network | `string` | `"10.0.0.0/16"` | no |
| create_nat_gateway | Whether to create a NAT Gateway | `bool` | `false` | no |
| nat_gateway_name | Name of the NAT Gateway | `string` | `"nat-gateway"` | no |
| nat_gateway_sku | SKU for the NAT Gateway | `string` | `"Standard"` | no |
| custom_tags | Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | ID of the virtual network |
| vnet_name | Name of the virtual network |
| vnet_address_space | Address space of the virtual network |
| subnet_ids | Map of subnet names to their IDs (`milvus`, `privatelink`) |
| subnet_address_prefixes | Map of subnet names to their address prefixes |
| nat_gateway_id | ID of the NAT Gateway (null if not created) |
| nat_gateway_public_ip_id | ID of the NAT Gateway public IP (null if not created) |
| network_security_group_id | ID of the Network Security Group |

## Notes

- The VNet uses Azure-provided DNS by default (no custom DNS servers)
- Subnet CIDRs are automatically calculated based on the VNet CIDR
- NAT Gateway is optional and only associated with the `milvus` subnet
- Both subnets have Microsoft.Storage service endpoints enabled
- Private endpoint and private link service network policies are enabled on both subnets

