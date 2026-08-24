moved {
  from = google_project_iam_member.gke_node_default
  to   = google_project_iam_member.gke_node_default[0]
}

moved {
  from = google_project_iam_member.gke_node_logging
  to   = google_project_iam_member.gke_node_logging[0]
}

moved {
  from = google_project_iam_member.gke_node_monitoring
  to   = google_project_iam_member.gke_node_monitoring[0]
}

moved {
  from = google_project_iam_custom_role.maintenance_cluster
  to   = google_project_iam_custom_role.maintenance_cluster[0]
}

moved {
  from = google_project_iam_member.maintenance_cluster
  to   = google_project_iam_member.maintenance_cluster[0]
}

moved {
  from = google_project_iam_custom_role.maintenance_operations
  to   = google_project_iam_custom_role.maintenance_operations[0]
}

moved {
  from = google_project_iam_member.maintenance_operations
  to   = google_project_iam_member.maintenance_operations[0]
}

moved {
  from = google_project_iam_custom_role.booter_kubernetes_bootstrap
  to   = google_project_iam_custom_role.booter_kubernetes_bootstrap[0]
}

moved {
  from = google_project_iam_member.booter_kubernetes_bootstrap
  to   = google_project_iam_member.booter_kubernetes_bootstrap[0]
}

moved {
  from = google_project_iam_custom_role.maintenance_project_reader
  to   = google_project_iam_custom_role.maintenance_project_reader[0]
}

moved {
  from = google_project_iam_member.maintenance_project_reader
  to   = google_project_iam_member.maintenance_project_reader[0]
}

moved {
  from = google_service_account_iam_member.management_can_use_node_sa
  to   = google_service_account_iam_member.management_can_use_node_sa[0]
}

moved {
  from = google_project_iam_member.storage_object_admin
  to   = google_project_iam_member.storage_object_admin[0]
}

moved {
  from = google_project_iam_member.storage_bucket_viewer
  to   = google_project_iam_member.storage_bucket_viewer[0]
}

moved {
  from = google_service_account_iam_member.storage_workload_identity_cluster
  to   = google_service_account_iam_member.storage_workload_identity_cluster[0]
}

moved {
  from = google_project_iam_custom_role.booter_self_delete
  to   = google_project_iam_custom_role.booter_self_delete[0]
}

moved {
  from = google_project_iam_member.booter_self_delete
  to   = google_project_iam_member.booter_self_delete[0]
}

moved {
  from = google_project_iam_custom_role.booter_zone_operation_viewer
  to   = google_project_iam_custom_role.booter_zone_operation_viewer[0]
}

moved {
  from = google_project_iam_member.booter_zone_operation_viewer
  to   = google_project_iam_member.booter_zone_operation_viewer[0]
}
