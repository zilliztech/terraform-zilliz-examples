data "google_compute_network" "existing" {
  count = local.create_vpc ? 0 : 1

  project = var.network_project_id
  name    = local.vpc_name
}

data "google_compute_subnetwork" "existing_primary" {
  count = local.create_primary_subnet ? 0 : 1

  project = var.network_project_id
  name    = local.primary_subnet_name
  region  = var.gcp_region
}

data "google_compute_subnetworks" "lb_candidates" {
  count = local.discover_lb_subnet ? 1 : 0

  project = var.network_project_id
  region  = var.gcp_region
  filter  = "(network = \"${local.vpc.self_link}\") AND (purpose = REGIONAL_MANAGED_PROXY) AND (role = ACTIVE)"
}

data "google_compute_subnetwork" "existing_lb" {
  count = local.create_lb_subnet ? 0 : 1

  project = var.network_project_id
  name    = local.discover_lb_subnet ? try(one(local.lb_candidates).name, local.lb_subnet_name) : local.lb_subnet_name
  region  = var.gcp_region

  lifecycle {
    precondition {
      condition     = !local.discover_lb_subnet || length(local.lb_candidates) == 1
      error_message = "Expected exactly one ACTIVE REGIONAL_MANAGED_PROXY subnet in the selected network project, VPC and region. Create one or specify lb_subnet.name."
    }
  }
}
