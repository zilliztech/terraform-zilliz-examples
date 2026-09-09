# The Workload Identity bindings moved out of module.iam into module.workload_identity
# so they are created after the GKE cluster that materialises the
# <gcp_project_id>.svc.id.goog Workload Identity pool.
moved {
  from = module.iam.google_service_account_iam_member.storage_workload_identity
  to   = module.workload_identity.google_service_account_iam_member.storage_workload_identity
}

moved {
  from = module.iam.google_service_account_iam_member.management_workload_identity
  to   = module.workload_identity.google_service_account_iam_member.management_workload_identity
}

moved {
  from = module.iam.google_service_account_iam_member.storage_workload_identity_cluster
  to   = module.workload_identity.google_service_account_iam_member.storage_workload_identity_cluster
}

# Preserve the enabled API when separating it from the other project services.
moved {
  from = google_project_service.required["cloudresourcemanager.googleapis.com"]
  to   = google_project_service.cloud_resource_manager
}
