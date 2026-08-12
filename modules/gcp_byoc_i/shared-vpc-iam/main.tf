data "google_project" "service" {
  project_id = var.service_project_id
}

locals {
  gke_service_agent    = "service-${data.google_project.service.number}@container-engine-robot.iam.gserviceaccount.com"
  cloud_services_agent = "${data.google_project.service.number}@cloudservices.gserviceaccount.com"
  network_users = toset([
    local.gke_service_agent,
    local.cloud_services_agent,
  ])
}

resource "google_project_iam_member" "gke_host_service_agent" {
  project = var.host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:${local.gke_service_agent}"
}

resource "google_compute_subnetwork_iam_member" "network_user" {
  for_each = local.network_users

  project    = var.host_project_id
  region     = var.gcp_region
  subnetwork = var.primary_subnet_name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${each.value}"
}
