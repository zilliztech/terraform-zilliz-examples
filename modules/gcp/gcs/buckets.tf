resource "google_storage_bucket" "byoc-buckets" {
  name     = "${var.storage_bucket_name}"
  location = var.gcp_region
  
  # Prevent public access
  public_access_prevention = "enforced"
}