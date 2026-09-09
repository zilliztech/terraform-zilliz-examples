mock_provider "google" {}
variables {
  gcp_project_id                  = "test-project"
  prefix_name                     = "test"
  gke_location                    = "us-central1"
  gke_cluster_name                = "test-cluster"
  storage_bucket_name             = "test-bucket"
  booter_instance_name            = "test-booter"
  booter_zone                     = "us-central1-a"
  service_account_mode            = "existing"
  enable_resource_manager_tags    = false
  manage_iam                      = false
  gke_node_service_account_name   = "shared-account"
  management_service_account_name = "shared-account"
  storage_service_account_name    = "shared-account"
  booter_service_account_name     = "shared-account"
}
run "reuse_one_account_for_all_roles" {
  command = plan
  assert {
    condition     = length(google_service_account.gke_node) == 0 && length(google_service_account.management) == 0 && length(google_service_account.storage) == 0 && length(google_service_account.booter) == 0
    error_message = "Shared existing accounts must be reused without creating accounts."
  }
}
run "existing_still_requires_all_names" {
  command = plan
  variables { booter_service_account_name = "" }
  expect_failures = [terraform_data.service_account_name_validation]
}
