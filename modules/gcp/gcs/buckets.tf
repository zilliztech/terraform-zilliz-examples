resource "google_storage_bucket" "byoc-buckets" {

  name     = "${var.storage_bucket_name}"
  location = var.gcp_region
}