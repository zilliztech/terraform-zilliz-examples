# Azure Private Link Module

This Terraform module creates an Azure Private Endpoint for connecting to Zilliz Cloud BYOC services, along with the necessary Private DNS Zone and DNS records.

## Features

- Creates Private Endpoint for Zilliz Cloud BYOC connectivity
- Creates Private DNS Zone for DNS resolution
- Links Private DNS Zone to Virtual Network
- Creates DNS A record pointing to the private endpoint IP
- Automatically configures DNS zone name based on Azure region
- Uses configuration from `conf.yaml` for Zilliz Cloud resource IDs

## Resources Created

- `azurerm_private_endpoint` - Private endpoint for Zilliz Cloud connection
- `azurerm_private_dns_zone` - Private DNS zone for name resolution
- `azurerm_private_dns_zone_virtual_network_link` - Links DNS zone to VNet
- `azurerm_private_dns_a_record` - DNS A record for root domain (@)

## Usage

```hcl
module "zilliz_private_endpoint" {
  source = "../../modules/azure/privatelink"

  private_endpoint_name = "zilliz-byoc-pe"
  location             = "East US"
  resource_group_name  = "rg-zilliz-byoc"
  subnet_id           = "/subscriptions/.../subnets/privatelink"
  vnet_id             = "/subscriptions/.../virtualNetworks/vnet-name"

  custom_tags = {
    Environment = "Production"
    Project     = "Zilliz-BYOC"
  }
}
```

## DNS Zone Configuration

The module automatically determines the DNS zone name based on the Azure region:
- Format: `cloud-tunnel.az-{region-short}.byoc.{domain-suffix}`
- Example: `cloud-tunnel.az-eastus.byoc.zillizcloud.com`

The DNS zone name and Zilliz Cloud resource ID are read from `conf.yaml`:
- `Azure.private_zone_domain_suffix`
- `Azure.zilliz_byoc_privatelink_resource_id[region]`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| private_endpoint_name | Name of the private endpoint | `string` | n/a | yes |
| location | Azure region where the private endpoint will be created | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_id | ID of the subnet where the private endpoint will be created | `string` | n/a | yes |
| vnet_id | ID of the virtual network to link DNS zones to | `string` | n/a | yes |
| custom_tags | Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| private_endpoint_id | ID of the private endpoint |
| private_endpoint_name | Name of the private endpoint |
| private_endpoint_network_interface_id | ID of the network interface associated with the private endpoint |
| private_dns_zone_id | ID of the created private DNS zone |
| private_dns_zone_name | Name of the created private DNS zone |
| private_dns_zone_vnet_link_id | ID of the DNS zone virtual network link |
| private_endpoint_ip_address | IP address of the private endpoint (sensitive) |

## Prerequisites

1. **conf.yaml**: The module requires a `conf.yaml` file at `../../conf.yaml` with:
   - `Azure.private_zone_domain_suffix`: Domain suffix for DNS zones
   - `Azure.zilliz_byoc_privatelink_resource_id`: Map of region to Zilliz Cloud resource ID

2. **Subnet**: The subnet specified in `subnet_id` must exist and be in the same VNet as `vnet_id`

3. **Resource Group**: The resource group must exist

## Notes

- The private endpoint uses automatic connection (not manual)
- DNS zone registration is disabled (registration_enabled = false)
- The DNS A record uses TTL of 300 seconds
- The private endpoint connection name is automatically generated as `{private_endpoint_name}-connection`
- The DNS zone group name is automatically generated as `{private_endpoint_name}-dns-zone-group`

## Example conf.yaml

```yaml
Azure:
  private_zone_domain_suffix: "zillizcloud.com"
  zilliz_byoc_privatelink_resource_id:
    eastus: "/subscriptions/.../providers/Microsoft.Network/privateLinkServices/zilliz-cloud-eastus"
    westus: "/subscriptions/.../providers/Microsoft.Network/privateLinkServices/zilliz-cloud-westus"
```

