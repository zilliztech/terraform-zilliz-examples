mock_provider "google" {}
variables {
  bucket_name    = "test-cmek-bucket"
  gcp_region     = "europe-west9"
  gcp_project_id = "test-project"
  enable_gcs_kms = true
}

run "create_software_key" {
  command = plan
  variables {

  }
  assert {
    condition     = google_kms_crypto_key.gcs[0].version_template[0].protection_level == "SOFTWARE"
    error_message = "New keys must use selected protection level, defaulting to SOFTWARE."
  }
}

run "create_hsm_key" {
  command = plan
  variables {
    kms_protection_level = "HSM"

  }
  assert {
    condition     = google_kms_crypto_key.gcs[0].version_template[0].protection_level == "HSM"
    error_message = "New keys must use selected protection level, defaulting to SOFTWARE."
  }
}
