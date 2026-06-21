resource "google_service_account" "gke_node" {
  project      = var.gcp_project_id
  account_id   = local.gke_node_sa_name
  display_name = "Zilliz BYOC-I GKE node service account"
}

resource "google_service_account" "management" {
  project      = var.gcp_project_id
  account_id   = local.management_sa_name
  display_name = "Zilliz BYOC-I maintenance service account"
}

resource "google_service_account" "storage" {
  project      = var.gcp_project_id
  account_id   = local.storage_sa_name
  display_name = "Zilliz BYOC-I storage service account"
}

resource "google_service_account" "booter" {
  project      = var.gcp_project_id
  account_id   = local.booter_sa_name
  display_name = "Zilliz BYOC-I booter service account"
}
