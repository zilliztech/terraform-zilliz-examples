output "bucket_id" {
  value = google_storage_bucket.this.name
}

output "bucket_url" {
  value = google_storage_bucket.this.url
}

output "kms_key_name" {
  value = local.effective_gcs_kms_key_name
}
