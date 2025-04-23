data "google_compute_zones" "available" {
  region = var.gcp_region
}

locals {
  azs = coalesce(var.gcp_zones, data.google_compute_zones.available.names)
  # subnet x/18 if vpc cidr x/16
  primary_subnet_cidr = coalesce(var.primary_subnet.cidr, cidrsubnet(var.gcp_vpc_cidr, 2, 0))
  pod_subnet_cidr      = coalesce(var.pod_subnet.cidr, cidrsubnet(var.gcp_vpc_cidr, 2, 1))
  service_subnet_cidr  = coalesce(var.service_subnet.cidr, cidrsubnet(var.gcp_vpc_cidr, 2, 2))
  # lb subnet x/20 if vpc cidr x/16
  region_lb_subnet_cidr = coalesce(var.lb_subnet.cidr, cidrsubnet(cidrsubnet(var.gcp_vpc_cidr, 2, 3), 2, 2))
}