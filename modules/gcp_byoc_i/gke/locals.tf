locals {
  create_cluster = var.gke_mode == "create"
  cluster = (
    local.create_cluster
    ? google_container_cluster.this[0]
    : data.google_container_cluster.existing[0]
  )

  existing_cluster_pod_range        = local.create_cluster ? "" : try(data.google_container_cluster.existing[0].ip_allocation_policy[0].cluster_secondary_range_name, "")
  existing_cluster_service_range    = local.create_cluster ? "" : try(data.google_container_cluster.existing[0].ip_allocation_policy[0].services_secondary_range_name, "")
  existing_cluster_workload_pool    = local.create_cluster ? "" : try(data.google_container_cluster.existing[0].workload_identity_config[0].workload_pool, "")
  existing_cluster_private_nodes    = local.create_cluster ? false : try(data.google_container_cluster.existing[0].private_cluster_config[0].enable_private_nodes, false)
  existing_cluster_encryption_state = local.create_cluster ? "" : try(data.google_container_cluster.existing[0].database_encryption[0].state, "")
  existing_cluster_encryption_key   = local.create_cluster ? "" : try(data.google_container_cluster.existing[0].database_encryption[0].key_name, "")
  existing_cluster_network          = local.create_cluster ? "" : trimprefix(data.google_container_cluster.existing[0].network, "https://www.googleapis.com/compute/v1/")
  existing_cluster_subnetwork       = local.create_cluster ? "" : trimprefix(data.google_container_cluster.existing[0].subnetwork, "https://www.googleapis.com/compute/v1/")
  selected_network                  = trimprefix(var.network_self_link, "https://www.googleapis.com/compute/v1/")
  selected_subnetwork               = trimprefix(var.primary_subnet_self_link, "https://www.googleapis.com/compute/v1/")

  common_labels = merge(
    {
      vendor     = "zilliz-byoc"
      managed_by = "terraform"
    },
    var.labels,
  )

  node_group_labels = {
    core = {
      "zilliz-group-name"     = "core"
      "node-role/etcd"        = "true"
      "node-role/pulsar"      = "true"
      "node-role/infra"       = "true"
      "node-role/vdc"         = "true"
      "node-role/milvus-tool" = "true"
      "capacity-type"         = "ON_DEMAND"
    }
    search = {
      "zilliz-group-name"    = "search"
      "node-role/diskANN"    = "true"
      "node-role/milvus"     = "true"
      "node-role/nvme-quota" = "200"
    }
    index = {
      "zilliz-group-name"    = "index"
      "node-role/index-pool" = "true"
    }
    fundamental = {
      "zilliz-group-name" = "fundamental"
      "node-role/default" = "true"
      "node-role/milvus"  = "true"
    }
    tiered = {
      "zilliz-group-name" = "tiered"
      "node-role/tiered"  = "true"
      "node-role/milvus"  = "true"
    }
  }

  node_group_local_ssd_counts = {
    search = 4
    tiered = 8
  }

  node_groups = {
    for name, group in var.k8s_node_groups : name => group
    if group.max_size > 0 && contains(keys(local.node_group_labels), name)
  }
}
