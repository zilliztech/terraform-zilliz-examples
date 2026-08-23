output "bucket_id" {
  value = var.bucket_mode == "create" ? google_storage_bucket.this[0].name : data.google_storage_bucket.this[0].name
}

output "bucket_url" {
  value = var.bucket_mode == "create" ? google_storage_bucket.this[0].url : data.google_storage_bucket.this[0].url
}

output "kms_key_name" {
  value = local.effective_gcs_kms_key_name
}
