resource "random_id" "short_uuid" {
  byte_length = 3
}

locals {
  short_project_id = substr(data.zillizcloud_byoc_i_project_settings.this.id, 0, 10)
  prefix_name      = "zilliz-${local.short_project_id}-${random_id.short_uuid.hex}"
  gcp_region       = trimprefix(data.zillizcloud_byoc_i_project_settings.this.region, "gcp-")
  gcp_zones        = var.gcp_zones != null ? var.gcp_zones : ["${local.gcp_region}-a", "${local.gcp_region}-b", "${local.gcp_region}-c"]

  project_id    = data.zillizcloud_byoc_i_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id

  enable_private_link = var.enable_private_link && data.zillizcloud_byoc_i_project_settings.this.private_link_enabled

  vpc_name         = var.customer_vpc_name != "" ? var.customer_vpc_name : "${local.prefix_name}-vpc"
  gke_cluster_name = var.customer_gke_cluster_name != "" ? var.customer_gke_cluster_name : "${local.prefix_name}-gke"
  booter_vm_name   = "${local.prefix_name}-booter"
  bucket_name_raw  = var.customer_bucket_name != "" ? var.customer_bucket_name : "${local.prefix_name}-bucket"
  bucket_name      = substr(lower(replace(local.bucket_name_raw, "_", "-")), 0, min(length(local.bucket_name_raw), 63))

  tiered_node_quota = (
    data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota != null
    ? { tiered = data.zillizcloud_byoc_i_project_settings.this.tiered_node_quota }
    : {}
  )

  k8s_node_groups = {
    for name, ng in merge(
      { tiered = { disk_size = 100, min_size = 0, max_size = 0, desired_size = 0, instance_types = "n2-standard-8", capacity_type = "ON_DEMAND" } },
      data.zillizcloud_byoc_i_project_settings.this.node_quotas,
      local.tiered_node_quota,
      ) : name => merge(ng, {
        disk_size = max(ng.disk_size, 100)
    })
  }

  dataplane_suffix = regex("[^-]+$", local.data_plane_id)
  env_domain       = var.env == "UAT" ? "cloud-uat3.zilliz.com" : "cloud.zilliz.com"
  module_config    = yamldecode(file("${path.module}/../../modules/conf.yaml"))
  agent_image_url  = data.zillizcloud_byoc_i_project_settings.this.op_config.agent_image_url
  gcp_agent_config = try(local.module_config.GCP.agent_config, {})
  agent_image_repository = (
    var.env == "UAT"
    ? try(local.gcp_agent_config.uat_repository, try(local.gcp_agent_config.repository, local.module_config.agent_config.repository))
    : try(local.gcp_agent_config.repository, local.module_config.agent_config.repository)
  )
  agent_image = (
    can(regex("/", local.agent_image_url))
    ? local.agent_image_url
    : "${local.agent_image_repository}:${local.agent_image_url}"
  )
  agent_server_host = (
    var.agent_server_host != ""
    ? var.agent_server_host
    : "cloud-tunnel.gcp-${local.gcp_region}.${local.env_domain}"
  )
  agent_endpoint_ip = (
    local.psc_endpoint_ip != null && can(regex("\\.byoc\\.", local.agent_server_host))
    ? local.psc_endpoint_ip
    : ""
  )
  agent_tunnel_host = (
    var.agent_tunnel_host != ""
    ? var.agent_tunnel_host
    : "k8s${local.dataplane_suffix}.gcp-${local.gcp_region}.byoc.${local.env_domain}"
  )
  psc_endpoint_ip = local.enable_private_link ? module.private_link[0].byoc_endpoint_ip : null
  storage_workload_identity_ksas = [
    {
      namespace = "index-pool"
      name      = "milvus-bucket"
    },
    {
      namespace = "milvus-tool"
      name      = "milvus-bucket"
    },
    {
      namespace = "loki"
      name      = "loki-loki-distributed"
    },
  ]

  common_labels = merge(
    {
      vendor     = "zilliz-byoc"
      data_plane = substr(lower(replace(local.data_plane_id, "_", "-")), 0, 63)
      zilliz_prj = substr(lower(replace(local.project_id, "_", "-")), 0, 63)
      managed_by = "terraform"
    },
    var.labels,
  )

  agent_config = {
    auth_token     = data.zillizcloud_byoc_i_project_settings.this.op_config.token
    image          = local.agent_image
    server_host    = local.agent_server_host
    tunnel_host    = local.agent_tunnel_host
    endpoint_ip    = local.agent_endpoint_ip
    gcp_project_id = var.gcp_project_id
  }

  ext_config = {
    gcp_project_id   = var.gcp_project_id
    gke_cluster_name = module.gke.cluster_name
  }
}
