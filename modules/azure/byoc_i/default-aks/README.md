# Azure Milvus AKS Module

This Terraform module creates an Azure Kubernetes Service (AKS) cluster specifically configured for running Milvus vector database workloads.

## Features

- **Private AKS Cluster** with private API server endpoint
- **Multiple Node Pools** optimized for different Milvus components (core, search, index, fundamental)
- **Auto-scaling** support for workload-based scaling
- **Network Integration** with existing VNet and subnets
- **Security Features** including RBAC, workload identity, and OIDC
- **Maintenance Identity** for cluster management operations
- **Storage Identity Integration** for accessing Azure Storage

## Node Pools

The module creates a default node pool (`agentpool`) and four additional node pools:

| Node Pool | Purpose | VM Size | Count | Auto-scaling |
|-----------|---------|---------|-------|--------------|
| `agentpool` | System components | Configurable | Configurable | Configurable |
| `core` | Core services | Standard_D4as_v5 | 1-50 | ✅ |
| `search` | Search workloads | Standard_L16s_v3 | 0-100 | ✅ |
| `index` | Index building | Standard_D8s_v5 | 0-100 | ✅ |
| `fundamental` | Fundamental services | Standard_D4as_v5 | 0-6 | ✅ |

**Note:** Node pool configurations can be customized via the `k8s_node_groups` variable. The `node_count` attribute is ignored after initial creation (lifecycle ignore_changes).

## Usage

```hcl
module "milvus_aks" {
  source = "../../modules/azure/standard-aks"

  prefix_name        = "zilliz-byoc"
  cluster_name       = "milvus-az-eastus-1"
  location           = "East US"
  resource_group_name = "rg-zilliz-byoc"
  subnet_id          = "/subscriptions/.../subnets/milvus"
  vnet_id            = "/subscriptions/.../virtualNetworks/vnet-name"
  storage_identity_id = "/subscriptions/.../userAssignedIdentities/storage-identity"
  kubernetes_version  = "1.32.4"

  # Default node pool configuration
  default_node_pool = {
    vm_size             = "Standard_D4as_v5"
    node_count          = 1
    min_count           = 1
    max_count           = 5
    enable_auto_scaling = true
  }

  # Additional node pools (k8s_node_groups)
  k8s_node_groups = {
    core = {
      vm_size         = "Standard_D4as_v5"
      min_size        = 1
      max_size        = 50
      desired_size    = 1
      os_disk_size_gb = 128
      os_disk_type    = "Managed"
    }
    search = {
      vm_size         = "Standard_L16s_v3"
      min_size        = 0
      max_size        = 100
      desired_size    = 0
      os_disk_size_gb = 160
      os_disk_type    = "Ephemeral"
    }
    # ... add more node groups as needed
  }

  custom_tags = {
    Environment = "Production"
    Project     = "Zilliz-BYOC"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| prefix_name | Prefix name for resource naming (e.g., 'zilliz-byoc') | `string` | `""` | no |
| cluster_name | Name of the AKS cluster | `string` | n/a | yes |
| location | Azure region where the AKS cluster will be created | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_id | ID of the subnet where the AKS cluster will be deployed | `string` | n/a | yes |
| vnet_id | Resource ID of the virtual network (required for maintenance identity role assignments) | `string` | n/a | yes |
| storage_identity_id | Resource ID of the storage identity (required for federated credential management) | `string` | n/a | yes |
| kubernetes_version | Kubernetes version for the AKS cluster (uses latest if not specified) | `string` | `null` | no |
| service_cidr | CIDR for Kubernetes services | `string` | `"10.255.0.0/16"` | no |
| default_node_pool | Configuration for the default node pool | `object` | See below | no |
| k8s_node_groups | Configuration for Kubernetes node groups (core, search, index, fundamental) | `map(object)` | See below | no |
| agent_tag | Agent image tag | `string` | n/a | yes |
| env | Environment name | `string` | `""` | no |
| dataplane_id | Dataplane ID | `string` | `""` | no |
| enable_private_endpoint | Whether to enable private endpoint for the AKS cluster | `bool` | `false` | no |
| custom_tags | Custom tags to apply to all resources (merged with Vendor=zilliz-byoc tag) | `map(string)` | `{}` | no |

### default_node_pool object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vm_size | VM size for nodes | `string` | `"Standard_D4as_v5"` |
| node_count | Initial number of nodes | `number` | `1` |
| min_count | Minimum number of nodes | `number` | `1` |
| max_count | Maximum number of nodes | `number` | `5` |
| enable_auto_scaling | Enable auto-scaling | `bool` | `true` |

### k8s_node_groups object

Each node group supports the following attributes:

| Name | Description | Type |
|------|-------------|------|
| vm_size | VM size for nodes | `string` |
| min_size | Minimum number of nodes | `number` |
| max_size | Maximum number of nodes | `number` |
| desired_size | Desired number of nodes (ignored after creation) | `number` |
| os_disk_size_gb | OS disk size in GB | `number` |
| os_disk_type | OS disk type (Managed or Ephemeral) | `string` |

**Note:** The `desired_size` attribute is ignored after initial creation via lifecycle ignore_changes. Use Azure auto-scaling or manual scaling to change node counts.

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the AKS cluster |
| cluster_name | Name of the AKS cluster |
| cluster_fqdn | FQDN of the AKS cluster |
| cluster_private_fqdn | Private FQDN of the AKS cluster |
| cluster_portal_fqdn | Portal FQDN of the AKS cluster |
| kube_config | Kubernetes configuration (sensitive) |
| kube_config_host | Kubernetes cluster host (sensitive) |
| kube_config_client_key | Kubernetes client key (sensitive) |
| kube_config_client_certificate | Kubernetes client certificate (sensitive) |
| kube_config_cluster_ca_certificate | Kubernetes cluster CA certificate (sensitive) |
| node_resource_group | Name of the node resource group |
| identity | Identity of the AKS cluster |
| node_pool_ids | Map of node pool names to IDs (core, search, index, fundamental) |
| node_pool_names | List of all additional node pool names |
| oidc_issuer_url | OIDC Issuer URL of the AKS cluster |
| oidc_issuer_url_last_two_segments | Last two segments of OIDC Issuer URL (for milvus.openid configuration) |
| kubelet_identity | Kubelet identity of the AKS cluster |
| maintenance_identity_id | ID of the maintenance user assigned managed identity |
| maintenance_identity_client_id | Client ID of the maintenance user assigned managed identity |
| maintenance_identity_principal_id | Principal ID of the maintenance user assigned managed identity |
| agentpool_identity_client_id | Client ID of the AKS agentpool managed identity |
| agentpool_identity_id | ID of the AKS agentpool managed identity |
| azurepolicy_identity_client_id | Client ID of the AKS azurepolicy managed identity |
| azurepolicy_identity_id | ID of the AKS azurepolicy managed identity |

## Prerequisites

1. **VNet and Subnet**: The subnet specified in `subnet_id` must exist
2. **Resource Group**: The resource group must exist
3. **Permissions**: Sufficient permissions to create AKS resources
4. **Azure CLI**: For kubectl access after deployment

## Post-deployment

After successful deployment:

1. **Get kubeconfig**:
   ```bash
   az aks get-credentials --resource-group <resource-group> --name <cluster-name>
   ```

2. **Verify cluster**:
   ```bash
   kubectl get nodes
   kubectl get nodes --show-labels
   ```

3. **Deploy Milvus**: Use the appropriate node selectors for different components:
   - `node-role/milvus=true` for Milvus components
   - `node-role/etcd=true` for etcd
   - `node-role/pulsar=true` for Pulsar
   - `node-role/index-pool=true` for index building

## Security Considerations

- **Private Cluster**: API server is not accessible from the internet (private_cluster_enabled = true)
- **RBAC**: Role-based access control is enabled
- **OIDC**: OpenID Connect issuer is enabled for workload identity
- **Network Policies**: Azure network policies are enabled
- **System Assigned Identity**: Cluster uses system-assigned managed identity
- **Maintenance Identity**: Separate user-assigned identity for maintenance operations
- **DNS Service IP**: Hardcoded to 10.255.0.10 (derived from service_cidr)

## Cost Optimization

- **Auto-scaling**: Node pools scale based on demand (min_size/max_size)
- **Right-sizing**: VM sizes are optimized for each workload type
- **Ephemeral OS**: Used for search node pool for better performance
- **Node Count Management**: `desired_size` is ignored after creation - use auto-scaling or manual scaling

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.0 |

## Resources

- [azurerm_kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)
- [azurerm_kubernetes_cluster_node_pool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool)
