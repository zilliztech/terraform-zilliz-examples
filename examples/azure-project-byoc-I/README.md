# Provisioning Azure Zilliz BYOC Project (WIP)

This example is using the following modules and [zilliz-cloud provider](https://registry.terraform.io/providers/zilliztech/zillizcloud/latest):
- [azure/byoc_i/default-virtual-networks module](../../modules/azure/byoc_i/default-virtual-networks)
- [azure/byoc_i/default-storageaccount module](../../modules/azure/byoc_i/default-storageaccount)
- [azure/byoc_i/default-storage-identity module](../../modules/azure/byoc_i/default-storage-identity)
- [azure/byoc_i/default-privatelink module](../../modules/azure/byoc_i/default-privatelink)
- [azure/byoc_i/default-aks module](../../modules/azure/byoc_i/default-aks)

This example provides a deployment of Zilliz Cloud BYOC project on Azure, including:
- Virtual Network with auto-split subnets and NAT Gateway
- Storage Account with Private Endpoint
- AKS cluster with configurable node pools
- User-assigned Managed Identity for storage access

## Prerequisites

Ensure that you are the owner of a BYOC-I organization.

## Procedures

### Step 1: Prepare the deployment environment

A deployment environment is a local machine, a virtual machine (VM), or a CI/CD pipeline configured to run the Terraform configuration files and deploy the data plane of your BYOC-I project. In this step, you need to:

1. Configure Azure credentials (Azure CLI or Service Principal).
   For details on how to configure Azure credentials, refer to this [document](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli).

2. Install the latest Terraform binary.
   For details on how to install Terraform, refer to this [document](https://developer.hashicorp.com/terraform/install?product_intent=terraform).

3. Configure authentication to zillizcloud providers.
   In the Zilliz Cloud console, go to your organization's API Keys page and copy your API key.
   Then, open the `provider.tf` file and set up authentication for the `zillizcloud` providers using that API key.
   ```hcl
   provider "zillizcloud" {
     api_key = "xxxxxxxxxxxxxxx"
   }
   ```

### Step 2: Configure input values to your terraform template

Navigate to `terraform.tfvars.json` and configure input values to your terraform template.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `subscription_id` | The ID of the Azure subscription | `string` | — | Yes |
| `resource_group_name` | Name of the Azure resource group | `string` | — | Yes |
| `project_id` | BYOC Project ID | `string` | — | Yes |
| `dataplane_id` | BYOC Dataplane ID | `string` | — | Yes |
| `vnet` | Virtual Network configuration | `object` | `{}` | No |
| `vnet.cidr` | CIDR block for the virtual network | `string` | `"10.0.0.0/16"` | No |
| `storage` | Storage Account configuration | `object` | `{}` | No |
| `storage.account_tier` | Storage account tier | `string` | `"Standard"` | No |
| `storage.account_replication_type` | Storage replication type | `string` | `"RAGRS"` | No |
| `storage.account_kind` | Storage account kind | `string` | `"StorageV2"` | No |
| `storage.minimum_tls_version` | Minimum TLS version | `string` | `"TLS1_2"` | No |
| `storage.allow_blob_public_access` | Allow blob public access | `bool` | `false` | No |
| `storage.network_default_action` | Default network action | `string` | `"Allow"` | No |
| `storage.public_network_access_enabled` | Enable public network access | `bool` | `true` | No |
| `storage.allowed_subnet_names` | Subnet names to allow (empty = all) | `list(string)` | `[]` | No |
| `customer_acr` | Customer ACR configuration | `object` | `{}` | No |
| `customer_acr.name` | ACR name | `string` | `""` | No |
| `customer_acr.prefix` | ACR prefix | `string` | `""` | No |
| `env` | Environment name | `string` | `"Production"` | No |
| `tags` | Custom tags to apply to resources | `map(string)` | `{}` | No |

Example minimal configuration (`terraform.tfvars.json`):
```json
{
  "subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "resource_group_name": "rg-my-byoc-project",
  "project_id": "proj-xxxxxxxxxx",
  "dataplane_id": "zilliz-byoc-azure-westus3-xxxxx"
}
```

Example configuration with custom options:
```json
{
  "subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "resource_group_name": "rg-my-byoc-project",
  "project_id": "proj-xxxxxxxxxx",
  "dataplane_id": "zilliz-byoc-azure-westus3-xxxxx",
  "vnet": {
    "cidr": "10.1.0.0/16"
  },
  "storage": {
    "account_tier": "Premium",
    "account_replication_type": "LRS"
  },
  "tags": {
    "Environment": "Production",
    "Team": "Data"
  }
}
```

### Step 3: Deploy to your Azure environment

Run the following commands to initialize the Terraform environment and apply the configuration:

Initialize Terraform: `terraform init`

Verify those resources will be created by Terraform: `terraform plan`

Apply the Configuration: `terraform apply`

Review the plan when prompted and type yes to confirm and proceed with the resource creation.

### Step 4: Verify Deployment

After the terraform apply command completes, verify that all resources have been successfully created. You can check the Azure Portal or use the Terraform state output for confirmation.

Output:

| Name | Description |
|------|-------------|
| `resource_group_name` | Resource group name |
| `vnet_id` | Virtual Network ID |
| `vnet_name` | Virtual Network name |
| `storage_account_id` | Storage Account ID |
| `storage_account_name` | Storage Account name |
| `storage_container_name` | Storage container name |
| `user_assigned_identity_id` | User-assigned Managed Identity ID |
| `aks_cluster_id` | AKS cluster ID |
| `aks_cluster_name` | AKS cluster name |


## File Structure

```
azure-project-byoc-I/
├── main.tf              # Module execution (calls Azure modules)
├── variables.tf         # Input variable definitions
├── locals.tf            # Configuration abstraction layer
├── outputs.tf           # Output values
├── provider.tf          # Provider configuration
├── terraform.tfvars.json # Example configuration
└── README.md            # This file
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |
| zillizcloud | latest |

## Related Modules

- [default-virtual-networks](../../modules/azure/byoc_i/default-virtual-networks/README.md)
- [default-storageaccount](../../modules/azure/byoc_i/default-storageaccount/README.md)
- [default-storage-identity](../../modules/azure/byoc_i/default-storage-identity/README.md)
- [default-privatelink](../../modules/azure/byoc_i/default-privatelink/README.md)
- [default-aks](../../modules/azure/byoc_i/default-aks/README.md)
