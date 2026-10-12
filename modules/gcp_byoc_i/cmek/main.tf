locals {
  prefix        = trimsuffix(substr(replace(lower(var.name_prefix), "_", "-"), 0, 24), "-")
  create_key    = var.enabled && var.key_name == ""
  email         = var.enabled ? google_service_account.cmek[0].email : ""
  key_name      = var.enabled ? (local.create_key ? google_kms_crypto_key.cmek[0].id : var.key_name) : ""
  key_iam_roles = var.enabled ? toset(["roles/cloudkms.cryptoKeyEncrypterDecrypter", "roles/cloudkms.viewer"]) : toset([])
}

resource "google_service_account" "cmek" {
  count        = var.enabled ? 1 : 0
  project      = var.project_id
  account_id   = "${local.prefix}-cmek"
  display_name = "Zilliz BYOC Milvus CMEK"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account_iam_member" "cmek_impersonation" {
  count              = var.enabled ? 1 : 0
  service_account_id = google_service_account.cmek[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.storage_service_account_email}"
}

resource "terraform_data" "validate" {
  lifecycle {
    precondition {
      condition     = !var.enabled || endswith(var.storage_service_account_email, "@${var.project_id}.iam.gserviceaccount.com")
      error_message = "The BYOC workload GSA used to impersonate CMEK must be in the customer project."
    }
    precondition {
      condition     = !var.enabled || var.key_name == "" || can(regex("^projects/[^/]+/locations/${var.region}/keyRings/[^/]+/cryptoKeys/[^/]+$", var.key_name))
      error_message = "CMEK key must be a CryptoKey resource in the DataPlane region, not a key version."
    }
  }
}

resource "google_kms_key_ring" "cmek" {
  count    = local.create_key ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = "${local.prefix}-cmek"
}

resource "google_kms_crypto_key" "cmek" {
  count           = local.create_key ? 1 : 0
  name            = "${local.prefix}-cmek"
  key_ring        = google_kms_key_ring.cmek[0].id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"
  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.protection_level
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "cmek" {
  for_each      = local.key_iam_roles
  crypto_key_id = local.key_name
  role          = each.value
  member        = "serviceAccount:${local.email}"
  depends_on    = [terraform_data.validate]
}

output "service_account_email" {
  value      = local.email
  depends_on = [google_service_account_iam_member.cmek_impersonation, terraform_data.validate]
}

output "key_name" {
  value      = local.key_name
  depends_on = [google_kms_crypto_key_iam_member.cmek, terraform_data.validate]
}
