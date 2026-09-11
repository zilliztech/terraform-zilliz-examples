mock_provider "google" {}

variables {
  gcp_project_id           = "test-project"
  gcp_region               = "europe-west9"
  gcp_zones                = ["europe-west9-a", "europe-west9-b", "europe-west9-c"]
  cluster_name             = "test-cluster"
  network_self_link        = "projects/test-project/global/networks/test"
  primary_subnet_self_link = "projects/test-project/regions/europe-west9/subnetworks/test"
  pod_subnet_name          = "pods"
  service_subnet_name      = "services"
  gke_node_sa_email        = "nodes@test-project.iam.gserviceaccount.com"
  k8s_node_groups = {
    search = { min_size = 3, max_size = 6, desired_size = 3, disk_size = 100, instance_types = "n2-standard-8", capacity_type = "ON_DEMAND" }
  }
}


run "defaults_remain_compatible" {
  command = plan
  assert {
    condition     = google_container_cluster.this[0].release_channel[0].channel == "UNSPECIFIED" && !google_container_node_pool.this["search"].management[0].auto_upgrade && google_container_node_pool.this["search"].node_config[0].disk_type == "pd-balanced" && google_container_node_pool.this["search"].node_config[0].ephemeral_storage_local_ssd_config[0].local_ssd_count == 4
    error_message = "Default upgrades, disk and Local SSD configuration must remain unchanged."
  }
}
run "pd_replaces_local_ssd_only_in_selected_pool" {
  command = plan
  variables {
    node_disk_size_gb           = 200
    node_group_local_ssd_counts = { search = 0 }
    node_group_disk_overrides   = { search = { disk_size_gb = 1500, disk_type = "pd-ssd" } }
  }
  assert {
    condition     = length(google_container_node_pool.this["search"].node_config[0].ephemeral_storage_local_ssd_config) == 0 && google_container_node_pool.this["search"].node_config[0].disk_size_gb == 1500 && google_container_node_pool.this["search"].node_config[0].disk_type == "pd-ssd" && google_container_node_pool.this["search"].node_config[0].labels["node-role/nvme-quota"] == "200" && local.node_group_local_ssd_counts["tiered"] == 8
    error_message = "SSD replacement must preserve scheduling labels and other pool defaults, and override global disk size."
  }
}
run "secrets_key_does_not_enable_boot_cmek" {
  command = plan
  variables {
    enable_secrets_encryption = true
    secrets_kms_key_name      = "projects/test-project/locations/europe-west9/keyRings/test/cryptoKeys/secrets"
  }
  assert {
    condition     = local.effective_boot_disk_kms_key_name == ""
    error_message = "Secrets encryption must not implicitly enable boot disk encryption."
  }
}
run "explicit_boot_cmek" {
  command = plan
  variables { boot_disk_kms_key_name = "projects/test-project/locations/europe-west9/keyRings/test/cryptoKeys/boot" }
  assert {
    condition     = google_container_cluster.this[0].node_config[0].boot_disk_kms_key == var.boot_disk_kms_key_name && google_container_node_pool.this["search"].node_config[0].boot_disk_kms_key == var.boot_disk_kms_key_name
    error_message = "Explicit boot CMEK must reach temporary and managed pools."
  }
}
run "channel_requires_explicit_upgrade_consent" {
  command = plan
  variables { release_channel = "REGULAR" }
  expect_failures = [google_container_node_pool.this["search"]]
}
run "opt_in_channel" {
  command = plan
  variables {
    release_channel   = "REGULAR"
    node_auto_upgrade = true
  }
  assert {
    condition     = google_container_node_pool.this["search"].management[0].auto_upgrade
    error_message = "Explicit upgrade opt-in must be honored."
  }
}
run "reject_bad_pool" {
  command = plan
  variables { node_group_local_ssd_counts = { serach = 0 } }
  expect_failures = [var.node_group_local_ssd_counts]
}
run "reject_negative_count" {
  command = plan
  variables { node_group_local_ssd_counts = { search = -1 } }
  expect_failures = [var.node_group_local_ssd_counts]
}
run "reject_small_disk" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 10, disk_type = "pd-ssd" } } }
  expect_failures = [var.node_group_disk_overrides]
}
run "hsm_secrets_key" {
  command = plan
  variables {
    enable_secrets_encryption = true
    kms_protection_level      = "HSM"
  }
  assert {
    condition     = google_kms_crypto_key.secrets[0].version_template[0].protection_level == "HSM"
    error_message = "Generated secrets key must use selected protection level."
  }
}

run "create_with_boot_key" {
  command = apply
  variables { boot_disk_kms_key_name = "projects/test-project/locations/europe-west9/keyRings/test/cryptoKeys/original" }
}
run "change_only_managed_pool_boot_key" {
  command = plan
  variables { boot_disk_kms_key_name = "projects/test-project/locations/europe-west9/keyRings/test/cryptoKeys/new" }
  assert {
    condition     = google_container_cluster.this[0].node_config[0].boot_disk_kms_key == "projects/test-project/locations/europe-west9/keyRings/test/cryptoKeys/original"
    error_message = "The deleted default pool must retain its creation-time key in the plan."
  }
  assert {
    condition     = google_container_cluster.this[0].id == run.create_with_boot_key.cluster_id && google_container_node_pool.this["search"].node_config[0].boot_disk_kms_key == var.boot_disk_kms_key_name
    error_message = "Keep the cluster identity while still managing the standalone node pool key."
  }
}
