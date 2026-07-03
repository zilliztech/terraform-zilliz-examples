output "gke_node_sa_email" {
  value = google_service_account.gke_node.email
}

output "management_sa_email" {
  value = google_service_account.management.email
}

output "storage_sa_email" {
  value = google_service_account.storage.email
}

output "booter_sa_email" {
  value = google_service_account.booter.email
}
