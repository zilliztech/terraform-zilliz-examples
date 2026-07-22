data "google_project" "this" {
  count = var.enable_gcs_kms && var.grant_gcs_kms_key_iam ? 1 : 0

  project_id = var.gcp_project_id
}

resource "terraform_data" "gcs_kms_input_validation" {
  input = {
    enable_gcs_kms        = var.enable_gcs_kms
    gcs_kms_key_name      = var.gcs_kms_key_name
    grant_gcs_kms_key_iam = var.grant_gcs_kms_key_iam
    gcp_project_id        = var.gcp_project_id
  }

  lifecycle {
    precondition {
      condition     = !var.enable_gcs_kms || var.gcs_kms_key_name != ""
      error_message = "gcs_kms_key_name must be non-empty when enable_gcs_kms is true."
    }

    precondition {
      condition     = !(var.enable_gcs_kms && var.grant_gcs_kms_key_iam) || var.gcp_project_id != ""
      error_message = "gcp_project_id must be non-empty when enable_gcs_kms and grant_gcs_kms_key_iam are true."
    }
  }
}

resource "google_kms_crypto_key_iam_member" "gcs_cmek" {
  count = var.enable_gcs_kms && var.grant_gcs_kms_key_iam ? 1 : 0

  crypto_key_id = var.gcs_kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this[0].number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [terraform_data.gcs_kms_input_validation]
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
      default_kms_key_name = var.gcs_kms_key_name
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gcs_cmek,
    terraform_data.gcs_kms_input_validation,
  ]
}
