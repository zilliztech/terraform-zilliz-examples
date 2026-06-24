resource "terraform_data" "service_account_name_validation" {
  input = {
    gke_node_sa_name   = local.gke_node_sa_name
    management_sa_name = local.management_sa_name
    storage_sa_name    = local.storage_sa_name
    booter_sa_name     = local.booter_sa_name
  }

  lifecycle {
    precondition {
      condition = length(distinct([
        local.gke_node_sa_name,
        local.management_sa_name,
        local.storage_sa_name,
        local.booter_sa_name,
      ])) == 4
      error_message = "GKE node, maintenance, storage, and booter service account names must be distinct. The booter VM must use a dedicated booter service account."
    }
  }
}

resource "google_service_account" "gke_node" {
  project      = var.gcp_project_id
  account_id   = local.gke_node_sa_name
  display_name = "Zilliz BYOC-I GKE node service account"

  depends_on = [terraform_data.service_account_name_validation]
}

resource "google_service_account" "management" {
  project      = var.gcp_project_id
  account_id   = local.management_sa_name
  display_name = "Zilliz BYOC-I maintenance service account"

  depends_on = [terraform_data.service_account_name_validation]
}

resource "google_service_account" "storage" {
  project      = var.gcp_project_id
  account_id   = local.storage_sa_name
  display_name = "Zilliz BYOC-I storage service account"

  depends_on = [terraform_data.service_account_name_validation]
}

resource "google_service_account" "booter" {
  project      = var.gcp_project_id
  account_id   = local.booter_sa_name
  display_name = "Zilliz BYOC-I booter service account"

  depends_on = [terraform_data.service_account_name_validation]
}
