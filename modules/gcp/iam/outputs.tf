output "management_sa_email" {
  description = "The email of the management service account"
  value       = google_service_account.management-sa.email
}

output "storage_sa_email" {
  description = "The email of the storage service account"
  value       = google_service_account.storage-sa.email
}

output "gke_node_sa_email" {
  description = "The email of the gke node service account"
  value       = google_service_account.gke-node-sa.email
}
