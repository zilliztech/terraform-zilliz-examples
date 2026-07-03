locals {
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

  node_groups = {
    for name, group in var.k8s_node_groups : name => group
    if group.max_size > 0 && contains(keys(local.node_group_labels), name)
  }
}
