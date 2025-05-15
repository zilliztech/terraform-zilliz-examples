output "cross_project_service_account_email" {
  description = "The email of the management service account"
  value       = google_service_account.management-sa.email
}

output "storage_service_account_email" {
  description = "The email of the storage service account"
  value       = google_service_account.storage-sa.email
}

output "gke_service_account_email" {
  description = "The email of the gke node service account"
  value       = google_service_account.gke-node-sa.email
}
