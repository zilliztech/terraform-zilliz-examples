mock_provider "google" {}
variables {
  gcp_project_id           = "test-project"
  gcp_region               = "us-central1"
  gcp_zones                = ["us-central1-a"]
  cluster_name             = "test-cluster"
  network_self_link        = "projects/test-project/global/networks/test-vpc"
  primary_subnet_self_link = "projects/test-project/regions/us-central1/subnetworks/test-primary"
  pod_subnet_name          = "test-pods"
  service_subnet_name      = ""
  gke_node_sa_email        = "nodes@test-project.iam.gserviceaccount.com"
  k8s_node_groups          = {}
}
run "managed_create_omits_range" {
  command = plan
  assert {
    condition     = google_container_cluster.this[0].ip_allocation_policy[0].cluster_secondary_range_name == "test-pods"
    error_message = "Managed Services must preserve the Pod range."
  }
}
run "custom_create_keeps_range" {
  command = plan
  variables { service_subnet_name = "test-services" }
  assert {
    condition     = google_container_cluster.this[0].ip_allocation_policy[0].services_secondary_range_name == "test-services"
    error_message = "Custom Service ranges must remain configured."
  }
}
run "managed_existing_cluster" {
  command = plan
  variables { gke_mode = "existing" }
  override_data {
    target = data.google_container_cluster.existing[0]
    values = {
      networking_mode          = "VPC_NATIVE"
      network                  = "projects/test-project/global/networks/test-vpc"
      subnetwork               = "projects/test-project/regions/us-central1/subnetworks/test-primary"
      ip_allocation_policy     = [{ cluster_secondary_range_name = "test-pods", services_secondary_range_name = "" }]
      private_cluster_config   = [{ enable_private_nodes = true }]
      workload_identity_config = [{ workload_pool = "test-project.svc.id.goog" }]
    }
  }
  assert {
    condition     = length(google_container_cluster.this) == 0
    error_message = "Existing managed clusters must be reused."
  }
}
run "managed_rejects_existing_custom_range" {
  command = plan
  variables { gke_mode = "existing" }
  override_data {
    target = data.google_container_cluster.existing[0]
    values = {
      networking_mode          = "VPC_NATIVE"
      network                  = "projects/test-project/global/networks/test-vpc"
      subnetwork               = "projects/test-project/regions/us-central1/subnetworks/test-primary"
      ip_allocation_policy     = [{ cluster_secondary_range_name = "test-pods", services_secondary_range_name = "test-services" }]
      private_cluster_config   = [{ enable_private_nodes = true }]
      workload_identity_config = [{ workload_pool = "test-project.svc.id.goog" }]
    }
  }
  expect_failures = [terraform_data.existing_cluster_validation]
}
