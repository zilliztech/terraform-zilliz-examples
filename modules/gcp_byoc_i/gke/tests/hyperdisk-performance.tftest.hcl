mock_provider "google" {}

variables {
  gcp_project_id              = "test-project"
  gcp_region                  = "europe-west9"
  gcp_zones                   = ["europe-west9-a", "europe-west9-b", "europe-west9-c"]
  cluster_name                = "test-cluster"
  network_self_link           = "projects/test-project/global/networks/test"
  primary_subnet_self_link    = "projects/test-project/regions/europe-west9/subnetworks/test"
  pod_subnet_name             = "pods"
  service_subnet_name         = "services"
  gke_node_sa_email           = "nodes@test-project.iam.gserviceaccount.com"
  node_group_local_ssd_counts = { search = 0 }
  k8s_node_groups = {
    search = { min_size = 3, max_size = 6, desired_size = 3, disk_size = 100, instance_types = "n4-standard-16", capacity_type = "ON_DEMAND" }
  }
}



run "explicit_performance" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced", provisioned_iops = 80000, provisioned_throughput = 1200 } } }
  assert {
    condition     = google_container_node_pool.this["search"].node_config[0].boot_disk[0].provisioned_iops == 80000 && google_container_node_pool.this["search"].node_config[0].boot_disk[0].provisioned_throughput == 1200
    error_message = "Performance values must reach boot_disk."
  }
}

run "iops_only" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced", provisioned_iops = 80000 } } }
  assert {
    condition     = google_container_node_pool.this["search"].node_config[0].boot_disk[0].provisioned_iops == 80000
    error_message = "Performance values must reach boot_disk."
  }
}

run "throughput_only" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced", provisioned_throughput = 300 } } }
  assert {
    condition     = google_container_node_pool.this["search"].node_config[0].boot_disk[0].provisioned_throughput == 300
    error_message = "Performance values must reach boot_disk."
  }
}

run "pd_rejects_iops" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "pd-ssd", provisioned_iops = 80000 } } }
  expect_failures = [var.node_group_disk_overrides]
}

run "reject_zero_iops" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced", provisioned_iops = 0 } } }
  expect_failures = [var.node_group_disk_overrides]
}

run "reject_fractional_throughput" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced", provisioned_throughput = 1.5 } } }
  expect_failures = [var.node_group_disk_overrides]
}
