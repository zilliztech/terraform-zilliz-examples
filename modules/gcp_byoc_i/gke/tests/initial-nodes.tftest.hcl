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
    core = { min_size = 3, max_size = 6, desired_size = 3, disk_size = 100, instance_types = "n2-standard-8", capacity_type = "ON_DEMAND" }
  }
}

run "three_total_across_three_zones" {
  command = plan
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 1 && google_container_node_pool.this["core"].autoscaling[0].total_min_node_count == 3
    error_message = "Three total nodes across three zones must initialize one node per zone, without changing autoscaling totals."
  }
}

run "one_zone_preserves_total" {
  command = plan
  variables { gcp_zones = ["europe-west9-a"] }
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 3
    error_message = "A single zone must retain the requested initial total."
  }
}

run "round_up_for_two_zones" {
  command = plan
  variables { gcp_zones = ["europe-west9-a", "europe-west9-b"] }
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 2
    error_message = "Round up per-zone initialization rather than start below the requested total."
  }
}

run "explicit_override_is_per_zone" {
  command = plan
  variables { node_initial_count = 2 }
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 2
    error_message = "Explicit per-zone overrides must remain backward compatible."
  }
}

run "zero_override_is_preserved" {
  command = plan
  variables { node_initial_count = 0 }
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 0
    error_message = "An explicit zero must not fall back to the default."
  }
}

run "reject_duplicate_zones" {
  command = plan
  variables { gcp_zones = ["europe-west9-a", "europe-west9-a"] }
  expect_failures = [var.gcp_zones]
}

run "desired_total_above_minimum" {
  command = plan
  variables {
    k8s_node_groups = {
      core = { min_size = 3, max_size = 9, desired_size = 6, disk_size = 100, instance_types = "n2-standard-8", capacity_type = "ON_DEMAND" }
    }
  }
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 2
    error_message = "The desired total must still take precedence over a lower minimum."
  }
}

run "minimum_above_desired_total" {
  command = plan
  variables {
    k8s_node_groups = {
      core = { min_size = 3, max_size = 6, desired_size = 1, disk_size = 100, instance_types = "n2-standard-8", capacity_type = "ON_DEMAND" }
    }
  }
  assert {
    condition     = google_container_node_pool.this["core"].initial_node_count == 1
    error_message = "The minimum total must take precedence over a lower desired count."
  }
}

run "reject_empty_zones" {
  command = plan
  variables { gcp_zones = [] }
  expect_failures = [var.gcp_zones]
}
