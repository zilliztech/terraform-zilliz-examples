mock_provider "google" {
  mock_resource "google_kms_key_ring" {
    defaults = { id = "projects/customer/locations/us-west1/keyRings/gcs" }
  }
  mock_resource "google_kms_crypto_key" {
    defaults = { id = "projects/customer/locations/us-west1/keyRings/gcs/cryptoKeys/gcs" }
  }
  mock_data "google_storage_project_service_account" {
    defaults = { email_address = "service-123@gs-project-accounts.iam.gserviceaccount.com" }
  }
}
variables {
  bucket_name    = "test-cmek-bucket"
  gcp_region     = "us-west1"
  gcp_project_id = "customer"
}
run "default_bucket_cmek" {
  command = apply
  assert {
    condition     = google_storage_bucket.this[0].encryption[0].default_kms_key_name == output.kms_key_name && output.kms_key_name != ""
    error_message = "The bucket must default to the created CMEK."
  }
  assert {
    condition     = google_kms_crypto_key_iam_member.gcs_cmek[0].member == "serviceAccount:service-123@gs-project-accounts.iam.gserviceaccount.com"
    error_message = "The GCS service agent must receive key access."
  }
}
run "disabled" {
  command = plan
  variables { enable_gcs_kms = false }
  assert {
    condition     = length(google_storage_bucket.this[0].encryption) == 0 && length(google_kms_crypto_key.gcs) == 0
    error_message = "Disabling CMEK must omit the encryption block and key."
  }
}
run "customer_key" {
  command = plan
  variables { gcs_kms_key_name = "projects/customer/locations/us-west1/keyRings/existing/cryptoKeys/gcs" }
  assert {
    condition     = google_storage_bucket.this[0].encryption[0].default_kms_key_name == var.gcs_kms_key_name && length(google_kms_crypto_key.gcs) == 0
    error_message = "The bucket must use the supplied key without creating another."
  }
}
