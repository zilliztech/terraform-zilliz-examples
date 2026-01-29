locals {

  # ============================================================================
  # Project Configuration
  # ============================================================================
  # Truncated project identifier for resource naming, limited to first 10 characters
  # Extracted from the Zilliz cloud BYOC project settings to ensure uniqueness
  short_project_id = substr(data.zillizcloud_byoc_i_project_settings.this.id, 0, 10)

  # Standardized naming prefix for all Azure resources created by this Terraform configuration
  # Combines "zilliz" brand, short project ID, and random hex for global uniqueness
  name_prefix = "zilliz-${local.short_project_id}-${random_id.short_uuid.hex}"

  # Flag indicating whether VPC private link should be enabled for secure connectivity
  # Determined by Zilliz cloud project configuration for enhanced network security
  enable_private_link = data.zillizcloud_byoc_i_project_settings.this.private_link_enabled

  # Configuration object for Zilliz monitoring and management agent
  # Contains authentication token and container image URL for agent deployment
  agent_config = {
    auth_token = data.zillizcloud_byoc_i_project_settings.this.op_config.token
    tag        = data.zillizcloud_byoc_i_project_settings.this.op_config.agent_image_url
  }

  # Kubernetes node group specifications and resource quotas
  # Defines the compute capacity and node types for the AKS cluster
  k8s_node_groups = data.zillizcloud_byoc_i_project_settings.this.node_quotas

  # Zilliz project identifier for resource tagging and organization
  # Links Azure resources back to the specific Zilliz cloud project
  project_id = data.zillizcloud_byoc_i_project_settings.this.project_id

  # Data plane identifier 
  # Used for consistency across different resource configurations
  data_plane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id

  # Azure region extracted from Zilliz cloud settings, removing "az-" prefix
  # Normalizes region format from Zilliz naming convention to standard Azure region names
  location = replace(data.zillizcloud_byoc_i_project_settings.this.region, "az-", "")

  # Resource group name from variable
  resource_group_name = var.resource_group_name

  # Common tags merged with user-provided tags
  common_tags = merge(
    {
      Vendor      = "zilliz-byoc"
      ManagedBy   = "terraform"
      Project     = local.project_id
      Environment = var.env
    },
    var.tags
  )

  # ============================================================================
  # VNet Configuration
  # ============================================================================
  vnet_config = {
    name                = "${local.name_prefix}-vnet"
    location            = local.location
    resource_group_name = local.resource_group_name
    cidr                = var.vnet.cidr

    # NAT Gateway configuration - created by default for outbound internet access
    create_nat_gateway = true
    nat_gateway_name   = "${local.name_prefix}-nat-gateway"

    tags = local.common_tags
  }

  vnet_id    = module.vnet.vnet_id
  vnet_name  = module.vnet.vnet_name
  subnet_ids = module.vnet.subnet_ids

  # ============================================================================
  # Storage Account Configuration
  # ============================================================================
  # Storage account name: only lowercase letters and numbers, 3-24 chars
  storage_account_name_raw = replace(local.name_prefix, "-", "")

  storage_config = {
    name                = substr(local.storage_account_name_raw, 0, 24)
    location            = local.location
    resource_group_name = local.resource_group_name

    # Storage account properties
    account_tier             = var.storage.account_tier
    account_replication_type = var.storage.account_replication_type
    account_kind             = var.storage.account_kind
    minimum_tls_version      = var.storage.minimum_tls_version

    # Network configuration - default: Allow all VNet subnets
    network_default_action        = var.storage.network_default_action
    public_network_access_enabled = var.storage.public_network_access_enabled
    allow_blob_public_access      = var.storage.allow_blob_public_access

    # Subnet IDs - if allowed_subnet_names is empty, allow all VNet subnets
    virtual_network_subnet_ids = length(var.storage.allowed_subnet_names) > 0 ? [
      for subnet_name in var.storage.allowed_subnet_names : local.subnet_ids[subnet_name]
    ] : values(local.subnet_ids)

    # Container configuration
    container_name        = "${local.name_prefix}-container"
    container_metadata    = var.storage.container_metadata
    container_access_type = var.storage.container_access_type

    tags = local.common_tags
  }

  storage_account_id   = module.storage_account.storage_account_id
  storage_account_name = module.storage_account.storage_account_name

  # Storage account scope for storage identity role assignment
  # Format: /subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{account}
  storage_account_scope = local.storage_account_id

  # ============================================================================
  # Identity Configuration
  # ============================================================================

  common_storage_identity_id = module.storage_identity.storage_identity.object_id

  # All instance storage identity IDs for federated credential management
  instance_storage_identity_ids = concat(
    [module.storage_identity.storage_identity.object_id],
    [for identity in module.storage_identity.instance_identities : identity.object_id]
  )

  storage_identities = concat(
    [{
      client_id    = module.storage_identity.storage_identity.client_id
      principal_id = module.storage_identity.storage_identity.principal_id
      resource_id  = module.storage_identity.storage_identity.object_id
    }],
    [
      for identity in module.storage_identity.instance_identities : {
        client_id    = identity.client_id
        principal_id = identity.principal_id
        resource_id  = identity.object_id
      }
    ]
  )

  # Maintenance Identity 
  maintenance_identity = {
    client_id    = module.milvus_aks.maintenance_identity_client_id
    principal_id = module.milvus_aks.maintenance_identity_principal_id
    resource_id  = module.milvus_aks.maintenance_identity_id
  }

  # Kubelet Identity 
  kubelet_identity = {
    client_id    = module.milvus_aks.kubelet_identity[0].client_id
    principal_id = module.milvus_aks.kubelet_identity[0].object_id
    resource_id  = module.milvus_aks.kubelet_identity[0].user_assigned_identity_id
  }

  # ============================================================================
  # Private Endpoint Configuration (for Zilliz Cloud Private Link)
  # ============================================================================
  # Private endpoint configuration - only created if enable_private_link is true
  # This is for Zilliz Cloud private link, not Storage Account private endpoint
  private_endpoint_config = {
    name                = "${local.name_prefix}-private-endpoint"
    location            = local.location
    resource_group_name = local.resource_group_name
    subnet_id           = local.subnet_ids["privatelink"]
    vnet_id             = local.vnet_id
    tags                = local.common_tags
  }

  # Private endpoint ID
  private_endpoint_id = local.enable_private_link ? module.zilliz_private_endpoint[0].private_endpoint_id : null

  # ============================================================================
  # AKS Configuration
  # ============================================================================
  # Default AKS configuration - converts node_pools to k8s_node_groups format
  aks_config = {
    cluster_name        = "${local.name_prefix}-aks"
    location            = local.location
    resource_group_name = local.resource_group_name

    # Kubernetes configuration - all use defaults
    kubernetes_version = null            # Use latest available version
    service_cidr       = "10.255.0.0/16" # Default value, can be overridden via variable

    # Default node pool configuration - always use defaults
    default_node_pool = {
      vm_size             = "Standard_D4as_v5"
      node_count          = 1
      min_count           = 1
      max_count           = 5
      enable_auto_scaling = true
    }

    # Convert node_quotas to k8s_node_groups format (similar to AWS EKS pattern)
    # Uses fixed mappings for node_labels and os_disk_type to ensure consistency
    k8s_node_groups = {
      for name, quota in local.k8s_node_groups : name => {
        vm_size         = quota.instance_types
        min_size        = quota.min_size
        max_size        = quota.max_size
        desired_size    = quota.desired_size
        os_disk_size_gb = quota.disk_size
      }
    }

    tags = local.common_tags
  }

  # AKS subnet name - always use milvus subnet
  aks_subnet_name = "milvus"

  # AKS subnet ID - use from subnet_ids map
  aks_subnet_id = local.subnet_ids[local.aks_subnet_name]

  # AKS Cluster
  aks_cluster_id   = module.milvus_aks.cluster_id
  aks_cluster_name = module.milvus_aks.cluster_name
  aks_issuer_url   = module.milvus_aks.oidc_issuer_url

  # ============================================================================
  # Extension configuration
  # ============================================================================
  ext_config = {
    aks = {
      name   = local.aks_cluster_name
      issuer = local.aks_issuer_url
    }
    acr = var.customer_acr
  }
}
