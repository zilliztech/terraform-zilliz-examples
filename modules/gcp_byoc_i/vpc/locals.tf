locals {
  vpc_name            = var.vpc_name != "" ? var.vpc_name : "${var.prefix_name}-vpc"
  primary_subnet_name = var.primary_subnet.name != "" ? var.primary_subnet.name : "${var.prefix_name}-primary"
  pod_subnet_name     = var.pod_subnet.name != "" ? var.pod_subnet.name : "${var.prefix_name}-pods"
  service_subnet_name = var.service_subnet.name != "" ? var.service_subnet.name : "${var.prefix_name}-services"
  lb_subnet_name      = var.lb_subnet.name != "" ? var.lb_subnet.name : "${var.prefix_name}-lb"
  router_name         = "${var.prefix_name}-router"
  nat_name            = "${var.prefix_name}-nat"

  primary_subnet_cidr = var.primary_subnet.cidr != "" ? var.primary_subnet.cidr : cidrsubnet(var.vpc_cidr, 4, 0)
  service_subnet_cidr = var.service_subnet.cidr != "" ? var.service_subnet.cidr : cidrsubnet(var.vpc_cidr, 4, 2)
  pod_subnet_cidr     = var.pod_subnet.cidr != "" ? var.pod_subnet.cidr : cidrsubnet(var.vpc_cidr, 2, 1)
  lb_subnet_cidr      = var.lb_subnet.cidr != "" ? var.lb_subnet.cidr : cidrsubnet(var.vpc_cidr, 8, 240)

  labels = merge(
    {
      vendor     = "zilliz-byoc"
      managed_by = "terraform"
    },
    var.labels,
  )
}
