resource "google_project_iam_member" "gke_node_default" {
  project = var.gcp_project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.gke_node.email}"

  condition {
    title       = "zilliz_byoc_i_target_cluster_node_sa"
    description = "Limit GKE node service account use to the target BYOC-I cluster"
    expression  = "resource.name == \"projects/${var.gcp_project_id}/locations/${var.gke_location}/clusters/${var.gke_cluster_name}\""
  }
}

resource "google_project_iam_member" "gke_node_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_member" "gke_node_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node.email}"
}

resource "google_project_iam_custom_role" "maintenance_cluster" {
  project     = var.gcp_project_id
  role_id     = "zillizByocIClusterMaintenance${local.role_suffix}"
  title       = "Zilliz BYOC-I Cluster Maintenance ${var.prefix_name}"
  description = "Minimum permissions for BYOC-I GKE node pool get/update operations"

  permissions = [
    "container.clusters.get",
    "container.clusters.update",
  ]
}

resource "google_project_iam_member" "maintenance_cluster" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.maintenance_cluster.id
  member  = "serviceAccount:${google_service_account.management.email}"

  condition {
    title       = "zilliz_byoc_i_target_cluster"
    description = "Limit maintenance to the target BYOC-I GKE cluster"
    expression  = "resource.name == \"projects/${var.gcp_project_id}/locations/${var.gke_location}/clusters/${var.gke_cluster_name}\""
  }
}

resource "google_project_iam_custom_role" "maintenance_operations" {
  project     = var.gcp_project_id
  role_id     = "zillizByocIOperationViewer${local.role_suffix}"
  title       = "Zilliz BYOC-I Operation Viewer ${var.prefix_name}"
  description = "Permissions for polling GKE async operations"

  permissions = [
    "container.operations.get",
    "container.operations.list",
  ]
}

resource "google_project_iam_member" "maintenance_operations" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.maintenance_operations.id
  member  = "serviceAccount:${google_service_account.management.email}"

  condition {
    title       = "zilliz_byoc_i_gke_operations"
    description = "Limit operation polling to the target GKE location"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/locations/${var.gke_location}/operations/\")"
  }
}

resource "google_project_iam_custom_role" "maintenance_project_reader" {
  project     = var.gcp_project_id
  role_id     = "zillizByocIProjectReader${local.role_suffix}"
  title       = "Zilliz BYOC-I Project Reader ${var.prefix_name}"
  description = "Minimum project metadata read permission for BYOC-I bootstrap"

  permissions = [
    "resourcemanager.projects.get",
  ]
}

resource "google_project_iam_member" "maintenance_project_reader" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.maintenance_project_reader.id
  member  = "serviceAccount:${google_service_account.management.email}"
}

resource "google_service_account_iam_member" "management_can_use_node_sa" {
  service_account_id = google_service_account.gke_node.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.management.email}"
}

resource "google_service_account_iam_member" "zilliz_byoc_can_impersonate_management" {
  service_account_id = google_service_account.management.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.zilliz_byoc_service_account_email}"
}

resource "google_project_iam_custom_role" "maintenance_mig_resize" {
  count = var.enable_direct_mig_resize ? 1 : 0

  project     = var.gcp_project_id
  role_id     = "zillizByocIMigResize${local.role_suffix}"
  title       = "Zilliz BYOC-I MIG Resize ${var.prefix_name}"
  description = "Optional permissions for resizing GKE-managed instance groups"

  permissions = [
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.update",
    "compute.zoneOperations.get",
  ]
}

resource "google_project_iam_member" "maintenance_mig_resize" {
  count = var.enable_direct_mig_resize ? 1 : 0

  project = var.gcp_project_id
  role    = google_project_iam_custom_role.maintenance_mig_resize[0].id
  member  = "serviceAccount:${google_service_account.management.email}"

  condition {
    title       = "zilliz_byoc_i_gke_mig_only"
    description = "Limit direct MIG resize to this GKE cluster managed instance groups"
    expression  = "resource.name.extract(\"instanceGroupManagers/{name}\").startsWith(\"gke-${var.gke_cluster_name}\")"
  }
}

resource "google_project_iam_member" "storage_object_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.storage.email}"

  condition {
    title       = "zilliz_byoc_i_storage_object_admin"
    description = "Limit storage object access to the BYOC-I bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.storage_bucket_name}\")"
  }
}

resource "google_project_iam_member" "storage_bucket_viewer" {
  project = var.gcp_project_id
  role    = "roles/storage.bucketViewer"
  member  = "serviceAccount:${google_service_account.storage.email}"

  condition {
    title       = "zilliz_byoc_i_storage_bucket_viewer"
    description = "Limit storage bucket metadata access to the BYOC-I bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.storage_bucket_name}\")"
  }
}

resource "google_service_account_iam_member" "storage_workload_identity" {
  for_each = {
    for ksa in var.storage_workload_identity_ksas :
    "${ksa.namespace}/${ksa.name}" => ksa
  }

  service_account_id = google_service_account.storage.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${each.value.namespace}/${each.value.name}]"
}

resource "google_project_iam_member" "booter_container_admin" {
  project = var.gcp_project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.booter.email}"
}
