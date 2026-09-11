mock_provider "google" {
  mock_resource "google_kms_key_ring" {
    defaults = { id = "projects/cluster-project/locations/us-west1/keyRings/test" }
  }
  mock_resource "google_kms_crypto_key" {
    defaults = { id = "projects/cluster-project/locations/us-west1/keyRings/test/cryptoKeys/pd" }
  }
  mock_data "google_project" {
    defaults = { number = "123456789" }
  }
}
variables {
  project_id  = "cluster-project"
  region      = "us-west1"
  name_prefix = "test-cluster"
}
run "enabled_creates_key_and_compute_grant" {
  command = apply
  variables { enabled = true }
  assert {
    condition     = length(google_kms_crypto_key.pd) == 1 && length(google_kms_crypto_key_iam_member.pd) == 1
    error_message = "Enabled CMEK must create a key and grant access."
  }
  assert {
    condition     = google_kms_crypto_key_iam_member.pd[0].member == "serviceAccount:service-123456789@compute-system.iam.gserviceaccount.com" && google_kms_crypto_key_iam_member.pd[0].crypto_key_id == output.key_name
    error_message = "The cluster Compute Engine agent must receive the effective key."
  }
}
run "disabled_by_default" {
  command = plan
  assert {
    condition     = output.key_name == "" && length(google_kms_crypto_key.pd) == 0 && length(google_kms_crypto_key_iam_member.pd) == 0
    error_message = "The default must create no key or grant."
  }
}
run "customer_key" {
  command = plan
  variables {
    enabled  = true
    key_name = "projects/key-project/locations/us-west1/keyRings/customer/cryptoKeys/pd"
  }
  assert {
    condition     = length(google_kms_crypto_key.pd) == 0 && length(google_kms_crypto_key_iam_member.pd) == 1 && output.key_name == var.key_name
    error_message = "Customer keys must be reused and granted."
  }
}
run "externally_granted" {
  command = plan
  variables {
    enabled       = true
    key_name      = "projects/key-project/locations/us-west1/keyRings/customer/cryptoKeys/pd"
    grant_key_iam = false
  }
  assert {
    condition     = length(google_kms_crypto_key_iam_member.pd) == 0 && output.key_name == var.key_name
    error_message = "Pre-authorized keys must not change IAM."
  }
}
run "wrong_region" {
  command = plan
  variables {
    enabled  = true
    key_name = "projects/key-project/locations/us-east1/keyRings/customer/cryptoKeys/pd"
  }
  expect_failures = [terraform_data.validate_key]
}
run "invalid_key" {
  command = plan
  variables {
    enabled  = true
    key_name = "not-a-key"
  }
  expect_failures = [var.key_name]
}

run "key_without_enable_remains_disabled" {
  command = plan
  variables {
    key_name = "projects/key-project/locations/us-west1/keyRings/customer/cryptoKeys/pd"
  }
  assert {
    condition     = output.key_name == "" && length(google_kms_crypto_key_iam_member.pd) == 0
    error_message = "Providing a key alone must not enable CMEK."
  }
}

run "create_software_key" {
  command = plan
  variables {
    enabled = true

  }
  assert {
    condition     = google_kms_crypto_key.pd[0].version_template[0].protection_level == "SOFTWARE"
    error_message = "New keys must use selected protection level, defaulting to SOFTWARE."
  }
}

run "create_hsm_key" {
  command = plan
  variables {
    enabled              = true
    kms_protection_level = "HSM"

  }
  assert {
    condition     = google_kms_crypto_key.pd[0].version_template[0].protection_level == "HSM"
    error_message = "New keys must use selected protection level, defaulting to SOFTWARE."
  }
}
