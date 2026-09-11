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


run "existing_without_boot_key" {
  command = apply
}
run "enable_boot_key_without_cluster_replacement" {
  command = plan
  variables { boot_disk_kms_key_name = "projects/test-project/locations/europe-west9/keyRings/test/cryptoKeys/new" }
  assert {
    condition     = google_container_cluster.this[0].id == run.existing_without_boot_key.cluster_id && length(google_container_cluster.this[0].node_config) == 0
    error_message = "Enabling CMEK must not replace a cluster whose default pool has already been deleted."
  }
  assert {
    condition     = google_container_node_pool.this["search"].node_config[0].boot_disk_kms_key == var.boot_disk_kms_key_name
    error_message = "CMEK must still be enabled on managed node pools."
  }
}
