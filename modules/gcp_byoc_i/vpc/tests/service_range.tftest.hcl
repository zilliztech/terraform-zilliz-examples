mock_provider "google" {}

variables {
  prefix_name        = "test"
  gcp_region         = "us-central1"
  gcp_project_id     = "test-project"
  network_project_id = "test-project"
  create_cloud_nat   = false
}

run "default_creates_service_range" {
  command = plan
  assert {
    condition     = output.service_subnet_name == "test-services" && length(google_compute_subnetwork.primary[0].secondary_ip_range) == 2
    error_message = "Default behavior must keep the custom Service range."
  }
}

run "managed_creates_only_pod_range" {
  command = plan
  variables {
    service_subnet = { mode = "gke-managed" }
  }
  assert {
    condition     = output.service_subnet_name == "" && output.service_subnet_cidr == "" && length(google_compute_subnetwork.primary[0].secondary_ip_range) == 1
    error_message = "Managed Services must not create or report a subnet secondary range."
  }
}

run "managed_existing_subnet" {
  command = plan
  variables {
    vpc_mode       = "existing"
    subnet_mode    = "existing"
    vpc_name       = "test-vpc"
    primary_subnet = { name = "test-primary" }
    pod_subnet     = { name = "test-pods" }
    service_subnet = { mode = "gke-managed" }
  }
  override_data {
    target = data.google_compute_network.existing[0]
    values = { self_link = "projects/test-project/global/networks/test-vpc" }
  }
  override_data {
    target = data.google_compute_subnetwork.existing_primary[0]
    values = {
      network            = "projects/test-project/global/networks/test-vpc"
      ip_cidr_range      = "10.0.0.0/24"
      secondary_ip_range = [{ range_name = "test-pods", ip_cidr_range = "10.1.0.0/16" }]
    }
  }
  assert {
    condition     = output.service_subnet_name == "" && output.service_subnet_cidr == "" && toset(google_compute_firewall.allow_local[0].source_ranges) == toset(["10.0.0.0/24", "10.1.0.0/16"])
    error_message = "An existing subnet only needs a Pod range; firewall sources must contain no empty CIDR."
  }
}

run "managed_rejects_name" {
  command = plan
  variables {
    service_subnet = { mode = "gke-managed", name = "custom-services" }
  }
  expect_failures = [var.service_subnet]
}

run "managed_rejects_cidr" {
  command = plan
  variables {
    service_subnet = { mode = "gke-managed", cidr = "10.2.0.0/24" }
  }
  expect_failures = [var.service_subnet]
}

run "rejects_unknown_mode" {
  command = plan
  variables {
    service_subnet = { mode = "unknown" }
  }
  expect_failures = [var.service_subnet]
}
