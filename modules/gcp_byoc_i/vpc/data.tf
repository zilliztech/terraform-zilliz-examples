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

data "google_compute_subnetwork" "existing_lb" {
  count = local.create_lb_subnet ? 0 : 1

  project = var.network_project_id
  name    = local.lb_subnet_name
  region  = var.gcp_region
}
