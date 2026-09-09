mock_provider "google" {
  mock_data "google_compute_network" {
    defaults = {
      self_link = "https://www.googleapis.com/compute/v1/projects/host-project/global/networks/test-vpc"
    }
  }
  mock_data "google_compute_subnetwork" {
    defaults = {
      name          = "existing-proxy"
      network       = "https://www.googleapis.com/compute/v1/projects/host-project/global/networks/test-vpc"
      ip_cidr_range = "10.3.0.0/24"
    }
  }
}

variables {
  prefix_name        = "test"
  gcp_region         = "us-central1"
  gcp_project_id     = "service-project"
  network_project_id = "host-project"
  vpc_mode           = "existing"
  vpc_name           = "test-vpc"
  lb_subnet_mode     = "existing"
  create_cloud_nat   = false
}

run "discovers_active_proxy_in_shared_vpc" {
  command = plan
  override_data {
    target = data.google_compute_subnetworks.lb_candidates[0]
    values = { subnetworks = [{ name = "existing-proxy" }] }
  }
  assert {
    condition     = data.google_compute_subnetworks.lb_candidates[0].project == "host-project" && data.google_compute_subnetworks.lb_candidates[0].region == "us-central1" && data.google_compute_subnetworks.lb_candidates[0].filter == "(network = \"https://www.googleapis.com/compute/v1/projects/host-project/global/networks/test-vpc\") AND (purpose = REGIONAL_MANAGED_PROXY) AND (role = ACTIVE)"
    error_message = "Discovery must filter the host project, region, VPC, purpose and active role."
  }
  assert {
    condition     = output.lb_subnet_name == "existing-proxy" && output.lb_subnet_cidr == "10.3.0.0/24" && length(google_compute_subnetwork.lb) == 0
    error_message = "Discovery must reuse the subnet and expose its actual name and CIDR."
  }
}

run "no_match_fails" {
  command = plan
  override_data {
    target = data.google_compute_subnetworks.lb_candidates[0]
    values = { subnetworks = [] }
  }
  expect_failures = [data.google_compute_subnetwork.existing_lb]
}

run "ambiguous_match_fails" {
  command = plan
  override_data {
    target = data.google_compute_subnetworks.lb_candidates[0]
    values = { subnetworks = [{ name = "proxy-a" }, { name = "proxy-b" }] }
  }
  expect_failures = [data.google_compute_subnetwork.existing_lb]
}

run "explicit_name_skips_discovery" {
  command = plan
  variables { lb_subnet = { name = "existing-proxy" } }
  assert {
    condition     = length(data.google_compute_subnetworks.lb_candidates) == 0 && data.google_compute_subnetwork.existing_lb[0].name == "existing-proxy"
    error_message = "Explicit names must retain direct lookup without list permission."
  }
}

run "create_keeps_default" {
  command = plan
  variables { lb_subnet_mode = "create" }
  assert {
    condition     = length(data.google_compute_subnetworks.lb_candidates) == 0 && google_compute_subnetwork.lb[0].name == "test-lb" && google_compute_subnetwork.lb[0].purpose == "REGIONAL_MANAGED_PROXY"
    error_message = "Create mode must preserve the default proxy subnet."
  }
}
