locals {
  create_vpc            = var.vpc_mode == "create"
  create_primary_subnet = var.subnet_mode == "create"
  create_lb_subnet      = var.lb_subnet_mode == "create"

  vpc_name             = var.vpc_name != "" ? var.vpc_name : "${var.prefix_name}-vpc"
  primary_subnet_name  = var.primary_subnet.name != "" ? var.primary_subnet.name : "${var.prefix_name}-primary"
  pod_subnet_name      = var.pod_subnet.name != "" ? var.pod_subnet.name : "${var.prefix_name}-pods"
  service_subnet_name  = var.service_subnet.name != "" ? var.service_subnet.name : "${var.prefix_name}-services"
  lb_subnet_name       = var.lb_subnet.name != "" ? var.lb_subnet.name : "${var.prefix_name}-lb"
  router_name          = "${var.prefix_name}-router"
  nat_name             = "${var.prefix_name}-nat"
  firewall_name_prefix = local.create_vpc ? local.vpc_name : var.prefix_name

  created_primary_subnet_cidr = var.primary_subnet.cidr != "" ? var.primary_subnet.cidr : cidrsubnet(var.vpc_cidr, 4, 0)
  created_service_subnet_cidr = var.service_subnet.cidr != "" ? var.service_subnet.cidr : cidrsubnet(var.vpc_cidr, 4, 2)
  created_pod_subnet_cidr     = var.pod_subnet.cidr != "" ? var.pod_subnet.cidr : cidrsubnet(var.vpc_cidr, 2, 1)
  created_lb_subnet_cidr      = var.lb_subnet.cidr != "" ? var.lb_subnet.cidr : cidrsubnet(var.vpc_cidr, 8, 240)

  vpc = local.create_vpc ? google_compute_network.this[0] : data.google_compute_network.existing[0]
  primary_subnet = (
    local.create_primary_subnet
    ? google_compute_subnetwork.primary[0]
    : data.google_compute_subnetwork.existing_primary[0]
  )
  lb_subnet = (
    local.create_lb_subnet
    ? google_compute_subnetwork.lb[0]
    : data.google_compute_subnetwork.existing_lb[0]
  )

  existing_pod_ranges = local.create_primary_subnet ? [] : [
    for secondary_range in data.google_compute_subnetwork.existing_primary[0].secondary_ip_range :
    secondary_range.ip_cidr_range if secondary_range.range_name == local.pod_subnet_name
  ]
  existing_service_ranges = local.create_primary_subnet ? [] : [
    for secondary_range in data.google_compute_subnetwork.existing_primary[0].secondary_ip_range :
    secondary_range.ip_cidr_range if secondary_range.range_name == local.service_subnet_name
  ]

  primary_subnet_cidr = local.create_primary_subnet ? local.created_primary_subnet_cidr : local.primary_subnet.ip_cidr_range
  pod_subnet_cidr     = local.create_primary_subnet ? local.created_pod_subnet_cidr : try(one(local.existing_pod_ranges), "")
  service_subnet_cidr = local.create_primary_subnet ? local.created_service_subnet_cidr : try(one(local.existing_service_ranges), "")
  lb_subnet_cidr      = local.create_lb_subnet ? local.created_lb_subnet_cidr : local.lb_subnet.ip_cidr_range
  internal_source_ranges = local.create_vpc ? [var.vpc_cidr] : distinct([
    local.primary_subnet_cidr,
    local.pod_subnet_cidr,
    local.service_subnet_cidr,
  ])

  labels = merge(
    {
      vendor     = "zilliz-byoc"
      managed_by = "terraform"
    },
    var.labels,
  )
}
