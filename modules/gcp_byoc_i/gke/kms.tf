locals {
  create_secrets_kms_key         = var.enable_secrets_encryption && var.secrets_kms_key_name == ""
  grant_secrets_kms_key_iam      = var.enable_secrets_encryption && (local.create_secrets_kms_key || var.grant_secrets_kms_key_iam)
  secrets_kms_name_prefix        = trimsuffix(substr(replace(lower(var.cluster_name), "_", "-"), 0, 50), "-")
  secrets_kms_key_ring_name      = "${local.secrets_kms_name_prefix}-secrets-kr"
  secrets_kms_crypto_key_name    = "${local.secrets_kms_name_prefix}-secrets-key"
  effective_secrets_kms_key_name = var.enable_secrets_encryption ? (var.secrets_kms_key_name != "" ? var.secrets_kms_key_name : google_kms_crypto_key.secrets[0].id) : ""
  provided_secrets_kms_location  = try(split("/", var.secrets_kms_key_name)[3], "")
}

data "google_project" "this" {
  count = local.grant_secrets_kms_key_iam ? 1 : 0

  project_id = var.gcp_project_id
}

resource "google_kms_key_ring" "secrets" {
  count = local.create_secrets_kms_key ? 1 : 0

  project  = var.gcp_project_id
  name     = local.secrets_kms_key_ring_name
  location = var.gcp_region
}

resource "google_kms_crypto_key" "secrets" {
  count = local.create_secrets_kms_key ? 1 : 0

  name     = local.secrets_kms_crypto_key_name
  key_ring = google_kms_key_ring.secrets[0].id
}

resource "google_kms_crypto_key_iam_member" "gke_secrets" {
  count = local.grant_secrets_kms_key_iam ? 1 : 0

  crypto_key_id = local.effective_secrets_kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this[0].number}@container-engine-robot.iam.gserviceaccount.com"

  depends_on = [google_kms_crypto_key.secrets]
}

resource "terraform_data" "secrets_encryption_validation" {
  count = var.enable_secrets_encryption && var.secrets_kms_key_name != "" ? 1 : 0

  input = {
    enabled  = var.enable_secrets_encryption
    key_name = var.secrets_kms_key_name
  }

  lifecycle {
    precondition {
      condition = (
        !var.enable_secrets_encryption ||
        var.secrets_kms_key_name == "" ||
        local.provided_secrets_kms_location == var.gcp_region
      )
      error_message = "The GKE Secrets encryption KMS key location must match gcp_region."
    }
  }
}
