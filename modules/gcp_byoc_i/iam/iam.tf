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

resource "google_project_iam_custom_role" "booter_kubernetes_bootstrap" {
  project     = var.gcp_project_id
  role_id     = "zillizByocIK8sBootstrap${local.role_suffix}"
  title       = "Zilliz BYOC-I Kubernetes Bootstrap ${var.prefix_name}"
  description = "Permissions for installing the BYOC-I cloud-agent Helm chart"

  permissions = [
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.clusterRoleBindings.create",
    "container.clusterRoleBindings.delete",
    "container.clusterRoleBindings.get",
    "container.clusterRoleBindings.list",
    "container.clusterRoleBindings.update",
    "container.clusterRoles.bind",
    "container.clusterRoles.create",
    "container.clusterRoles.delete",
    "container.clusterRoles.escalate",
    "container.clusterRoles.get",
    "container.clusterRoles.list",
    "container.clusterRoles.update",
    "container.deployments.create",
    "container.deployments.delete",
    "container.deployments.get",
    "container.deployments.getStatus",
    "container.deployments.list",
    "container.deployments.update",
    "container.namespaces.create",
    "container.namespaces.get",
    "container.namespaces.getStatus",
    "container.namespaces.list",
    "container.namespaces.update",
    "container.pods.get",
    "container.pods.getLogs",
    "container.pods.getStatus",
    "container.pods.list",
    "container.replicaSets.get",
    "container.replicaSets.getStatus",
    "container.replicaSets.list",
    "container.secrets.create",
    "container.secrets.delete",
    "container.secrets.get",
    "container.secrets.list",
    "container.secrets.update",
    "container.serviceAccounts.create",
    "container.serviceAccounts.get",
    "container.serviceAccounts.list",
    "container.serviceAccounts.update",
    "container.services.create",
    "container.services.delete",
    "container.services.get",
    "container.services.getStatus",
    "container.services.list",
    "container.services.update",
    "container.services.updateStatus",
  ]
}

resource "google_project_iam_member" "booter_kubernetes_bootstrap" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.booter_kubernetes_bootstrap.id
  member  = "serviceAccount:${google_service_account.booter.email}"
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

resource "google_service_account_iam_member" "storage_workload_identity_cluster" {
  service_account_id = google_service_account.storage.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.storage_cluster_workload_identity_member
}

resource "google_project_iam_custom_role" "booter_self_delete" {
  project = var.gcp_project_id
  role_id = "zillizByocIBooterDelete${local.role_suffix}"
  title   = "Zilliz BYOC-I Booter Self Delete ${var.prefix_name}"
  description = (
    var.enable_resource_manager_tags
    ? "Permissions for the booter service account to delete tagged BYOC-I booter instances"
    : "Permissions for the booter service account to delete the named BYOC-I booter instance"
  )

  permissions = [
    "compute.instances.get",
    "compute.instances.delete",
  ]
}

resource "terraform_data" "booter_self_delete_tag_validation" {
  input = {
    enabled      = var.enable_resource_manager_tags
    tag_key_id   = var.vendor_tag_key_id
    tag_value_id = var.vendor_tag_value_id
  }

  lifecycle {
    precondition {
      condition = (
        !var.enable_resource_manager_tags ||
        (
          can(regex("^tagKeys/[0-9]+$", var.vendor_tag_key_id)) &&
          can(regex("^tagValues/[0-9]+$", var.vendor_tag_value_id))
        )
      )
      error_message = "vendor_tag_key_id and vendor_tag_value_id must be non-empty tagKeys/<numeric-id> and tagValues/<numeric-id> when enable_resource_manager_tags is true."
    }
  }
}

resource "google_project_iam_member" "booter_self_delete" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.booter_self_delete.id
  member  = "serviceAccount:${google_service_account.booter.email}"

  condition {
    title       = "zilliz_byoc_i_booter_self_delete"
    description = "Limit booter VM self-delete to the configured BYOC-I booter instance boundary"
    expression  = local.booter_self_delete_condition
  }

  depends_on = [terraform_data.booter_self_delete_tag_validation]
}

resource "google_project_iam_custom_role" "booter_zone_operation_viewer" {
  project     = var.gcp_project_id
  role_id     = "zillizByocIBooterOpViewer${local.role_suffix}"
  title       = "Zilliz BYOC-I Booter Operation Viewer ${var.prefix_name}"
  description = "Permissions for polling booter VM self-delete zone operations"

  permissions = [
    "compute.zoneOperations.get",
  ]
}

resource "google_project_iam_member" "booter_zone_operation_viewer" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.booter_zone_operation_viewer.id
  member  = "serviceAccount:${google_service_account.booter.email}"

  condition {
    title       = "zilliz_byoc_i_booter_zone_operations"
    description = "Limit booter self-delete operation polling to the target zone"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/zones/${var.booter_zone}/operations/\")"
  }
}
