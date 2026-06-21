resource "google_storage_bucket" "this" {
  name                        = var.bucket_name
  location                    = var.gcp_region
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = merge(
    {
      vendor     = "zilliz-byoc"
      managed_by = "terraform"
    },
    var.labels,
  )
}
