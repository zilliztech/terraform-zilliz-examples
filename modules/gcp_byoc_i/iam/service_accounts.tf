resource "terraform_data" "service_account_name_validation" {
  input = {
    gke_node_sa_name   = local.gke_node_sa_name
    management_sa_name = local.management_sa_name
    storage_sa_name    = local.storage_sa_name
    booter_sa_name     = local.booter_sa_name
  }

  lifecycle {
    precondition {
      condition = var.service_account_mode != "existing" || alltrue([
        var.gke_node_service_account_name != "",
        var.management_service_account_name != "",
        var.storage_service_account_name != "",
        var.booter_service_account_name != "",
      ])
      error_message = "All four service account names are required when service_account_mode is existing."
    }

    precondition {
      condition     = var.manage_iam || var.service_account_mode == "existing"
      error_message = "manage_iam can be false only when service_account_mode is existing."
    }
  }
}

resource "google_service_account" "gke_node" {
  count = local.create_service_accounts ? 1 : 0

  project      = var.gcp_project_id
  account_id   = local.gke_node_sa_name
  display_name = "Zilliz BYOC-I GKE node service account"

  depends_on = [terraform_data.service_account_name_validation]
}

resource "google_service_account" "management" {
  count = local.create_service_accounts ? 1 : 0

  project      = var.gcp_project_id
  account_id   = local.management_sa_name
  display_name = "Zilliz BYOC-I maintenance service account"

  depends_on = [terraform_data.service_account_name_validation]
}

resource "google_service_account" "storage" {
  count = local.create_service_accounts ? 1 : 0

  project      = var.gcp_project_id
  account_id   = local.storage_sa_name
  display_name = "Zilliz BYOC-I storage service account"

  depends_on = [terraform_data.service_account_name_validation]
}

resource "google_service_account" "booter" {
  count = local.create_service_accounts ? 1 : 0

  project      = var.gcp_project_id
  account_id   = local.booter_sa_name
  display_name = "Zilliz BYOC-I booter service account"

  depends_on = [terraform_data.service_account_name_validation]
}

data "google_service_account" "gke_node" {
  count = local.create_service_accounts ? 0 : 1

  project    = var.gcp_project_id
  account_id = local.gke_node_sa_name
}

data "google_service_account" "management" {
  count = local.create_service_accounts ? 0 : 1

  project    = var.gcp_project_id
  account_id = local.management_sa_name
}

data "google_service_account" "storage" {
  count = local.create_service_accounts ? 0 : 1

  project    = var.gcp_project_id
  account_id = local.storage_sa_name
}

data "google_service_account" "booter" {
  count = local.create_service_accounts ? 0 : 1

  project    = var.gcp_project_id
  account_id = local.booter_sa_name
}

moved {
  from = google_service_account.gke_node
  to   = google_service_account.gke_node[0]
}

moved {
  from = google_service_account.management
  to   = google_service_account.management[0]
}

moved {
  from = google_service_account.storage
  to   = google_service_account.storage[0]
}

moved {
  from = google_service_account.booter
  to   = google_service_account.booter[0]
}
