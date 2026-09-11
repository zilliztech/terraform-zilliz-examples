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


run "n4_hyperdisk_boot" {
  command = plan
  variables {
    k8s_node_groups = {
      search = { min_size = 1, max_size = 3, desired_size = 1, disk_size = 100, instance_types = "n4-standard-16", capacity_type = "ON_DEMAND" }
    }
    node_group_local_ssd_counts = { search = 0 }
    node_group_disk_overrides   = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced" } }
  }
  assert {
    condition     = google_container_node_pool.this["search"].node_config[0].disk_type == "hyperdisk-balanced" && google_container_node_pool.this["search"].node_config[0].disk_size_gb == 1500 && length(google_container_node_pool.this["search"].node_config[0].ephemeral_storage_local_ssd_config) == 0
    error_message = "Hyperdisk Balanced boot disk overrides must reach the node pool."
  }
}
run "reject_n2_hyperdisk_boot" {
  command = plan
  variables { node_group_disk_overrides = { search = { disk_size_gb = 1500, disk_type = "hyperdisk-balanced" } } }
  expect_failures = [google_container_node_pool.this["search"]]
}
run "reject_n4_implicit_pd_default" {
  command = plan
  variables {
    k8s_node_groups = {
      search = { min_size = 1, max_size = 3, desired_size = 1, disk_size = 100, instance_types = "n4-standard-16", capacity_type = "ON_DEMAND" }
    }
    node_group_local_ssd_counts = { search = 0 }
  }
  expect_failures = [google_container_node_pool.this["search"]]
}
run "reject_n4_explicit_pd" {
  command = plan
  variables {
    k8s_node_groups = {
      search = { min_size = 1, max_size = 3, desired_size = 1, disk_size = 100, instance_types = "n4-standard-16", capacity_type = "ON_DEMAND" }
    }
    node_group_disk_overrides   = { search = { disk_size_gb = 1500, disk_type = "pd-ssd" } }
    node_group_local_ssd_counts = { search = 0 }
  }
  expect_failures = [google_container_node_pool.this["search"]]
}
