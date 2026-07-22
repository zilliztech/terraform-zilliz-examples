locals {
  create_gcs_kms_key         = var.enable_gcs_kms && var.gcs_kms_key_name == ""
  grant_gcs_kms_key_iam      = var.enable_gcs_kms && (local.create_gcs_kms_key || var.grant_gcs_kms_key_iam)
  auto_gcs_kms_name_prefix   = trimsuffix(substr(replace(replace(lower(var.bucket_name), ".", "-"), "_", "-"), 0, 50), "-")
  gcs_kms_key_ring_name      = "${local.auto_gcs_kms_name_prefix}-kr"
  gcs_kms_crypto_key_name    = "${local.auto_gcs_kms_name_prefix}-key"
  effective_gcs_kms_key_name = var.enable_gcs_kms ? (var.gcs_kms_key_name != "" ? var.gcs_kms_key_name : google_kms_crypto_key.gcs[0].id) : ""
}

data "google_project" "this" {
  count = local.grant_gcs_kms_key_iam ? 1 : 0

  project_id = var.gcp_project_id
}

resource "google_kms_key_ring" "gcs" {
  count = local.create_gcs_kms_key ? 1 : 0

  project  = var.gcp_project_id
  name     = local.gcs_kms_key_ring_name
  location = var.gcp_region
}

resource "google_kms_crypto_key" "gcs" {
  count = local.create_gcs_kms_key ? 1 : 0

  name     = local.gcs_kms_crypto_key_name
  key_ring = google_kms_key_ring.gcs[0].id
}

resource "google_kms_crypto_key_iam_member" "gcs_cmek" {
  count = local.grant_gcs_kms_key_iam ? 1 : 0

  crypto_key_id = local.effective_gcs_kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this[0].number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [google_kms_crypto_key.gcs]
}

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

  dynamic "encryption" {
    for_each = var.enable_gcs_kms ? [1] : []

    content {
      default_kms_key_name = local.effective_gcs_kms_key_name
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gcs_cmek,
  ]
}
