mock_provider "google" {}

variables {
  project_id                    = "customer-project"
  region                        = "us-west1"
  name_prefix                   = "test-cluster"
  storage_service_account_email = "storage-gsa@customer-project.iam.gserviceaccount.com"
}

run "disabled_has_no_cloud_resources" {
  command = plan
  assert {
    condition     = length(google_service_account.cmek) == 0 && length(google_kms_crypto_key.cmek) == 0 && length(google_kms_crypto_key_iam_member.cmek) == 0 && output.service_account_email == ""
    error_message = "Default configuration must not change customer cloud resources."
  }
}

run "new_key_uses_dedicated_identity_and_scoped_grants" {
  command = plan
  variables { enabled = true }
  assert {
    condition     = length(google_service_account.cmek) == 1 && length(google_service_account_iam_member.cmek_impersonation) == 1 && length(google_kms_crypto_key.cmek) == 1 && length(google_kms_crypto_key_iam_member.cmek) == 2
    error_message = "Create a dedicated GSA, impersonation grant, key and two key-scoped IAM grants."
  }
  assert {
    condition     = google_service_account.cmek[0].project == var.project_id && google_service_account.cmek[0].account_id == "test-cluster-cmek"
    error_message = "The dedicated CMEK GSA must be created in the customer project."
  }
  assert {
    condition     = google_service_account_iam_member.cmek_impersonation[0].member == "serviceAccount:${var.storage_service_account_email}"
    error_message = "The DataPlane workload GSA must be able to impersonate the dedicated CMEK GSA."
  }
  assert {
    condition     = google_kms_crypto_key.cmek[0].purpose == "ENCRYPT_DECRYPT" && google_kms_crypto_key.cmek[0].version_template[0].algorithm == "GOOGLE_SYMMETRIC_ENCRYPTION"
    error_message = "Milvus requires a standard symmetric encrypt/decrypt key."
  }
}

run "existing_resources_are_not_recreated" {
  command = plan
  variables {
    enabled  = true
    key_name = "projects/key-project/locations/us-west1/keyRings/ring/cryptoKeys/key"
  }
  assert {
    condition     = length(google_kms_crypto_key.cmek) == 0 && output.key_name == var.key_name && length(google_service_account.cmek) == 1
    error_message = "Existing keys must be reused with a dedicated CMEK service account."
  }
  assert {
    condition     = length(google_kms_crypto_key_iam_member.cmek) == 2
    error_message = "Existing keys receive scoped grants by default."
  }
}

run "foreign_project_storage_identity_is_rejected" {
  command = plan
  variables {
    enabled                       = true
    storage_service_account_email = "storage-gsa@other-project.iam.gserviceaccount.com"
  }
  expect_failures = [terraform_data.validate]
}

run "wrong_region_is_rejected" {
  command = plan
  variables {
    enabled  = true
    key_name = "projects/key-project/locations/us-east1/keyRings/ring/cryptoKeys/key"
  }
  expect_failures = [terraform_data.validate]
}
