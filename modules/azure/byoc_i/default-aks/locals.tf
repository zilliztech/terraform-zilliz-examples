data "azurerm_location" "current" {
  location = var.location
}

locals {
  # Load config file (similar to AWS EKS pattern)
  config = yamldecode(file("${path.module}/../../../conf.yaml"))

  # Prefix name for resource naming (similar to AWS EKS pattern)
  prefix_name = var.prefix_name != "" ? var.prefix_name : replace(var.cluster_name, "-", "")

  # Node groups configuration (similar to AWS EKS pattern)
  k8s_node_groups = var.k8s_node_groups

  # Convert location display name to short name using Azure data source
  location = data.azurerm_location.current.location

  # Get Azure agent config from config file based on location
  # Default to empty map if location not found in config
  azure_agent_config = try(local.config.Azure.agent_config[local.location], {})

  # Hosts

  # The regex [^-]+$ matches one or more non-hyphen characters at the end of the string
  # zilliz-byoc-azure-southeastasia-xxxyyyzzz -> xxxyyyzzz
  dataplane_suffix = regex("[^-]+$", var.dataplane_id)
  env_domain       = var.env == "UAT" ? "cloud-uat3.zilliz.com" : "cloud.zilliz.com"
  # if enable_private_endpoint is true, the server_host is cloud-tunnel.az-southeastasia.byoc.cloud.zilliz.com, otherwise it is cloud-tunnel.az-southeastasia.zilliz.com
  server_host      = "cloud-tunnel.az-${local.location}${var.enable_private_endpoint ? ".byoc" : ""}.${local.env_domain}"
  # k8sxxxyyyzzz.az-southeastasia.byoc.cloud.zilliz.com
  tunnel_host      = "k8s${local.dataplane_suffix}.az-${local.location}.byoc.${local.env_domain}"

  # Standard tags for all resources (similar to AWS EKS pattern)
  # Merge Vendor tag with custom_tags
  common_tags = merge(
    {
      "Vendor" = "zilliz-byoc"
    },
    var.custom_tags
  )

  # Standard node labels pattern (similar to AWS EKS)
  # Each node pool should have:
  # - zilliz-group-name: the group name
  # - node-role/*: role-specific labels


  # Core node pool labels (matching AWS EKS core group)
  core_node_labels = {
    "zilliz-group-name"     = "core"
    "node-role/etcd"        = "true"
    "node-role/pulsar"      = "true"
    "node-role/infra"       = "true"
    "node-role/vdc"         = "true"
    "node-role/milvus-tool" = "true"
    "capacity-type"         = "ON_DEMAND"
  }

  # Search node pool labels (matching AWS EKS search group)
  search_node_labels = {
    "zilliz-group-name"    = "search"
    "node-role/diskANN"    = "true"
    "node-role/milvus"     = "true"
    "node-role/nvme-quota" = "200"
  }

  # Index node pool labels (matching AWS EKS index group)
  index_node_labels = {
    "zilliz-group-name"    = "index"
    "node-role/index-pool" = "true"
  }

  # Fundamental node pool labels (matching AWS EKS fundamental group)
  fundamental_node_labels = {
    "zilliz-group-name" = "fundamental"
    "node-role/default" = "true"
    "node-role/milvus"  = "true"
  }

  # Default node pool labels (for agentpool)
  default_node_labels = {
    "zilliz-group-name" = "agentpool"
    "node-role"         = "agentpool"
  }

  # Maintenance identity name
  maintenance_identity_name = "${var.cluster_name}-maintenance-identity"

  # Disk type
  core_disk_type        = "Managed"
  search_disk_type      = "Ephemeral"
  index_disk_type       = "Managed"
  fundamental_disk_type = "Managed"

  # OS SKU
  os_sku = "Ubuntu"
}

