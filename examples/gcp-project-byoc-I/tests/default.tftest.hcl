mock_provider "google" {}
mock_provider "zillizcloud" {}

override_data {
  target = data.zillizcloud_byoc_i_project_settings.this
  values = {
    id                       = "settings-id"
    project_id               = "zilliz-project"
    project_name             = "test-project"
    data_plane_id            = "zilliz-byoc-gcp-us-west1-123456789012"
    cloud_provider           = "gcp"
    region                   = "gcp-us-west1"
    private_link_enabled     = false
    agent_bootstrap_required = false
    tiered_node_quota = {
      disk_size      = 100
      min_size       = 0
      max_size       = 0
      desired_size   = 0
      instance_types = "n2-standard-8"
      capacity_type  = "ON_DEMAND"
    }
    node_quotas = {
      core = {
        disk_size      = 100
        min_size       = 1
        max_size       = 3
        desired_size   = 1
        instance_types = "n2-standard-8"
        capacity_type  = "ON_DEMAND"
      }
      fundamental = {
        disk_size      = 100
        min_size       = 1
        max_size       = 3
        desired_size   = 1
        instance_types = "n2-standard-8"
        capacity_type  = "ON_DEMAND"
      }
      index = {
        disk_size      = 100
        min_size       = 1
        max_size       = 3
        desired_size   = 1
        instance_types = "n2-standard-8"
        capacity_type  = "ON_DEMAND"
      }
      search = {
        disk_size      = 100
        min_size       = 1
        max_size       = 3
        desired_size   = 1
        instance_types = "n2-standard-8"
        capacity_type  = "ON_DEMAND"
      }
    }
    op_config = {
      token           = "test-token"
      agent_image_url = "test-tag"
    }
  }
}

run "creates_network_and_gke_by_default" {
  command = plan

  variables {
    project_id                   = "zilliz-project"
    dataplane_id                 = "zilliz-byoc-gcp-us-west1-123456789012"
    gcp_project_id               = "customer-service-project"
    enable_private_link          = false
    enable_resource_manager_tags = false
  }

  assert {
    condition     = length(module.vpc) == 1
    error_message = "The default path must continue creating the VPC module."
  }

  assert {
    condition     = length(module.gke) == 1
    error_message = "The default path must continue creating the GKE module."
  }
}

run "rejects_existing_gke_without_existing_network" {
  command = plan

  variables {
    project_id                   = "zilliz-project"
    dataplane_id                 = "zilliz-byoc-gcp-us-west1-123456789012"
    gcp_project_id               = "customer-service-project"
    enable_private_link          = false
    enable_resource_manager_tags = false
    existing_gke = {
      cluster_name               = "customer-gke"
      node_service_account_email = "gke-node@customer-service-project.iam.gserviceaccount.com"
    }
  }

  expect_failures = [terraform_data.existing_infrastructure_validation]
}

run "reuses_existing_shared_vpc_and_gke" {
  command = plan

  variables {
    project_id                   = "zilliz-project"
    dataplane_id                 = "zilliz-byoc-gcp-us-west1-123456789012"
    gcp_project_id               = "customer-service-project"
    enable_private_link          = false
    enable_resource_manager_tags = false
    existing_network = {
      network_project_id           = "customer-network-host-project"
      vpc_name                     = "shared-vpc"
      primary_subnet_name          = "primary"
      pod_secondary_range_name     = "pods"
      service_secondary_range_name = "services"
      lb_subnet_name               = "proxy-only"
    }
    existing_gke = {
      cluster_name               = "customer-gke"
      node_service_account_email = "gke-node@customer-service-project.iam.gserviceaccount.com"
    }
  }

  override_data {
    target = data.google_compute_network.existing[0]
    values = {
      name      = "shared-vpc"
      self_link = "projects/customer-network-host-project/global/networks/shared-vpc"
    }
  }

  override_data {
    target = data.google_compute_subnetwork.existing_primary[0]
    values = {
      name          = "primary"
      network       = "projects/customer-network-host-project/global/networks/shared-vpc"
      self_link     = "projects/customer-network-host-project/regions/us-west1/subnetworks/primary"
      ip_cidr_range = "10.0.0.0/20"
      secondary_ip_range = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.16.0.0/14"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.20.0.0/20"
        },
      ]
    }
  }

  override_data {
    target = data.google_compute_subnetwork.existing_lb[0]
    values = {
      name          = "proxy-only"
      network       = "projects/customer-network-host-project/global/networks/shared-vpc"
      self_link     = "projects/customer-network-host-project/regions/us-west1/subnetworks/proxy-only"
      ip_cidr_range = "10.21.0.0/23"
    }
  }

  override_data {
    target = data.google_container_cluster.existing[0]
    values = {
      name            = "customer-gke"
      location        = "us-west1"
      network         = "projects/customer-network-host-project/global/networks/shared-vpc"
      subnetwork      = "projects/customer-network-host-project/regions/us-west1/subnetworks/primary"
      networking_mode = "VPC_NATIVE"
      node_locations  = ["us-west1-a", "us-west1-b", "us-west1-c"]
      private_cluster_config = [{
        enable_private_nodes    = true
        enable_private_endpoint = true
        master_ipv4_cidr_block  = "172.16.0.0/28"
      }]
      workload_identity_config = [{
        workload_pool = "customer-service-project.svc.id.goog"
      }]
      ip_allocation_policy = [{
        cluster_secondary_range_name  = "pods"
        services_secondary_range_name = "services"
      }]
      node_pool = [
        {
          name = "core"
          node_config = [{
            service_account = "gke-node@customer-service-project.iam.gserviceaccount.com"
            labels = {
              "zilliz-group-name"     = "core"
              "node-role/etcd"        = "true"
              "node-role/pulsar"      = "true"
              "node-role/infra"       = "true"
              "node-role/vdc"         = "true"
              "node-role/milvus-tool" = "true"
              "capacity-type"         = "ON_DEMAND"
            }
          }]
        },
        {
          name = "fundamental"
          node_config = [{
            service_account = "gke-node@customer-service-project.iam.gserviceaccount.com"
            labels = {
              "zilliz-group-name" = "fundamental"
              "node-role/default" = "true"
              "node-role/milvus"  = "true"
            }
          }]
        },
        {
          name = "index"
          node_config = [{
            service_account = "gke-node@customer-service-project.iam.gserviceaccount.com"
            labels = {
              "zilliz-group-name"    = "index"
              "node-role/index-pool" = "true"
            }
          }]
        },
        {
          name = "search"
          node_config = [{
            service_account = "gke-node@customer-service-project.iam.gserviceaccount.com"
            labels = {
              "zilliz-group-name"    = "search"
              "node-role/diskANN"    = "true"
              "node-role/milvus"     = "true"
              "node-role/nvme-quota" = "200"
            }
          }]
        },
      ]
    }
  }

  assert {
    condition     = length(module.vpc) == 0
    error_message = "The existing Shared VPC path must not create the VPC module."
  }

  assert {
    condition     = length(module.gke) == 0
    error_message = "The existing GKE path must not create the GKE module."
  }

  assert {
    condition     = output.gke_cluster_name == "customer-gke"
    error_message = "The existing GKE cluster name must flow to the BYOC-I configuration."
  }

  assert {
    condition     = module.iam.gke_node_sa_email == "gke-node@customer-service-project.iam.gserviceaccount.com"
    error_message = "The existing GKE node service account must be reused by the IAM module."
  }
}
