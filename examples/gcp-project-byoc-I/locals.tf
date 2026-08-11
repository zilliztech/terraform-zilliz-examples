locals {
  project_id    = data.zillizcloud_byoc_i_project_settings.this.project_id
  data_plane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id
  data_plane_id_last12 = substr(
    local.data_plane_id,
    max(length(local.data_plane_id) - 12, 0),
    min(length(local.data_plane_id), 12),
  )
  prefix_name       = "zilliz-dp-${local.data_plane_id_last12}"
  gcp_region        = trimprefix(data.zillizcloud_byoc_i_project_settings.this.region, "gcp-")
  default_gcp_zones = var.gcp_zones != null ? var.gcp_zones : ["${local.gcp_region}-a", "${local.gcp_region}-b", "${local.gcp_region}-c"]

  enable_private_link = var.enable_private_link && data.zillizcloud_byoc_i_project_settings.this.private_link_enabled

  is_existing_network = var.existing_network != null
  is_existing_gke     = var.existing_gke != null

  network_project_id = local.is_existing_network ? var.existing_network.network_project_id : var.gcp_project_id

  vpc_name         = var.customer_vpc_name != "" ? var.customer_vpc_name : "${local.prefix_name}-vpc"
  gke_cluster_name = local.is_existing_gke ? var.existing_gke.cluster_name : (var.customer_gke_cluster_name != "" ? var.customer_gke_cluster_name : "${local.prefix_name}-gke")
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

  required_node_pool_names = toset([
    for name, group in local.k8s_node_groups : name
    if group.max_size > 0 && contains(keys(local.required_node_pool_labels), name)
  ])

  required_node_pool_labels = {
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

  existing_primary_secondary_ranges = local.is_existing_network ? {
    for secondary_range in data.google_compute_subnetwork.existing_primary[0].secondary_ip_range :
    secondary_range.range_name => secondary_range.ip_cidr_range
  } : {}

  existing_node_pools = local.is_existing_gke ? {
    for node_pool in data.google_container_cluster.existing[0].node_pool :
    node_pool.name => node_pool
  } : {}

  resolved_vpc_name = local.is_existing_network ? data.google_compute_network.existing[0].name : module.vpc[0].vpc_name
  network_self_link = local.is_existing_network ? data.google_compute_network.existing[0].self_link : module.vpc[0].vpc_self_link

  primary_subnet_name      = local.is_existing_network ? data.google_compute_subnetwork.existing_primary[0].name : module.vpc[0].primary_subnet_name
  primary_subnet_self_link = local.is_existing_network ? data.google_compute_subnetwork.existing_primary[0].self_link : module.vpc[0].primary_subnet_self_link
  primary_subnet_cidr      = local.is_existing_network ? data.google_compute_subnetwork.existing_primary[0].ip_cidr_range : module.vpc[0].primary_subnet_cidr

  pod_subnet_name     = local.is_existing_network ? var.existing_network.pod_secondary_range_name : module.vpc[0].pod_subnet_name
  pod_subnet_cidr     = local.is_existing_network ? lookup(local.existing_primary_secondary_ranges, var.existing_network.pod_secondary_range_name, null) : module.vpc[0].pod_subnet_cidr
  service_subnet_name = local.is_existing_network ? var.existing_network.service_secondary_range_name : module.vpc[0].service_subnet_name
  service_subnet_cidr = local.is_existing_network ? lookup(local.existing_primary_secondary_ranges, var.existing_network.service_secondary_range_name, null) : module.vpc[0].service_subnet_cidr

  lb_subnet_name = local.is_existing_network ? data.google_compute_subnetwork.existing_lb[0].name : module.vpc[0].lb_subnet_name
  lb_subnet_cidr = local.is_existing_network ? data.google_compute_subnetwork.existing_lb[0].ip_cidr_range : module.vpc[0].lb_subnet_cidr

  gcp_zones = local.is_existing_gke ? sort(tolist(data.google_container_cluster.existing[0].node_locations)) : local.default_gcp_zones
  booter_zone = try(
    local.gcp_zones[0],
    local.default_gcp_zones[0],
  )
  master_ipv4_cidr_block = local.is_existing_gke ? try(
    data.google_container_cluster.existing[0].private_cluster_config[0].master_ipv4_cidr_block,
    null,
  ) : var.master_ipv4_cidr_block

  dataplane_suffix               = regex("[^-]+$", local.data_plane_id)
  env_domain                     = var.env == "UAT" ? "cloud-uat3.zilliz.com" : "cloud.zilliz.com"
  module_config                  = yamldecode(file("${path.module}/../../modules/conf.yaml"))
  psc_service_attachment_project = var.env == "UAT" ? "vdc-dev-test" : "vdc-prod"
  psc_service_attachment_name    = "zilliz-byoc-psc-dns"
  gcp_psc_service_attachment_id = (
    var.gcp_psc_service_attachment_id != ""
    ? var.gcp_psc_service_attachment_id
    : "projects/${local.psc_service_attachment_project}/regions/${local.gcp_region}/serviceAttachments/${local.psc_service_attachment_name}"
  )
  gcp_private_service_domain = "gcp-${local.gcp_region}.byoc.${local.env_domain}"
  psc_private_dns_domain = (
    var.gcp_psc_private_dns_domain != ""
    ? var.gcp_psc_private_dns_domain
    : "${local.gcp_private_service_domain}."
  )
  psc_private_dns_record_names = length(var.gcp_psc_private_dns_record_names) > 0 ? var.gcp_psc_private_dns_record_names : [
    "cloud-tunnel.${local.gcp_private_service_domain}.",
    "cloud-open-api.${local.gcp_private_service_domain}.",
  ]
  agent_image_url = data.zillizcloud_byoc_i_project_settings.this.op_config.agent_image_url
  agent_image_tag = (
    can(regex("/", local.agent_image_url)) && can(regex(":", local.agent_image_url))
    ? element(split(":", local.agent_image_url), length(split(":", local.agent_image_url)) - 1)
    : local.agent_image_url
  )
  gcp_agent_config  = try(local.module_config.GCP.agent_config, {})
  gcp_booter_config = try(local.module_config.GCP.booter_config, {})
  image_repo_url    = trimsuffix(trimspace(var.image_repo_url), "/")
  booter_image_repository = (
    local.image_repo_url != ""
    ? "${local.image_repo_url}/gcp-byoc-i-booter"
    : (
      var.env == "UAT"
      ? try(local.gcp_booter_config.uat_repository, local.gcp_booter_config.repository)
      : local.gcp_booter_config.repository
    )
  )
  booter_image = (
    var.booter_image != ""
    ? var.booter_image
    : "${local.booter_image_repository}:latest"
  )
  agent_image_repository = (
    local.image_repo_url != ""
    ? "${local.image_repo_url}/cloud-agent"
    : (
      var.env == "UAT"
      ? try(local.gcp_agent_config.uat_repository, try(local.gcp_agent_config.repository, local.module_config.agent_config.repository))
      : try(local.gcp_agent_config.repository, local.module_config.agent_config.repository)
    )
  )
  agent_image = (
    local.image_repo_url != ""
    ? "${local.agent_image_repository}:${local.agent_image_tag}"
    : (
      can(regex("/", local.agent_image_url))
      ? local.agent_image_url
      : "${local.agent_image_repository}:${local.agent_image_url}"
    )
  )
  agent_server_host = (
    var.agent_server_host != ""
    ? var.agent_server_host
    : "cloud-tunnel.gcp-${local.gcp_region}${local.enable_private_link ? ".byoc" : ""}.${local.env_domain}"
  )
  agent_endpoint_ip = (
    local.psc_endpoint_ip != null
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
    gke_cluster_name = local.gke_cluster_name
  }
}
