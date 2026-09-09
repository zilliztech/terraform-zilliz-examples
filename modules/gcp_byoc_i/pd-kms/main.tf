locals {
  create_key = var.enabled && var.key_name == ""
  grant_iam  = var.enabled && (local.create_key || var.grant_key_iam)
  prefix     = trimsuffix(substr(replace(lower(var.name_prefix), "_", "-"), 0, 50), "-")
  key_name   = var.enabled ? (var.key_name != "" ? var.key_name : google_kms_crypto_key.pd[0].id) : ""
}

resource "google_kms_key_ring" "pd" {
  count    = local.create_key ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = "${local.prefix}-pd-kr"
}
resource "google_kms_crypto_key" "pd" {
  count    = local.create_key ? 1 : 0
  name     = "${local.prefix}-pd-key"
  key_ring = google_kms_key_ring.pd[0].id
}

data "google_project" "cluster" {
  count      = local.grant_iam ? 1 : 0
  project_id = var.project_id
}
resource "google_kms_crypto_key_iam_member" "pd" {
  count         = local.grant_iam ? 1 : 0
  crypto_key_id = local.key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.cluster[0].number}@compute-system.iam.gserviceaccount.com"
}
resource "terraform_data" "validate_key" {
  lifecycle {
    precondition {
      condition     = !var.enabled || var.key_name == "" || try(split("/", var.key_name)[3] == var.region, false)
      error_message = "The PD KMS key location must match the GKE region."
    }
  }
}
output "key_name" {
  value      = local.key_name
  depends_on = [google_kms_crypto_key_iam_member.pd, terraform_data.validate_key]
}
