resource "terraform_data" "existing_cluster_validation" {
  count = local.create_cluster ? 0 : 1

  input = {
    cluster_name = var.cluster_name
    gke_mode     = var.gke_mode
  }

  lifecycle {
    precondition {
      condition     = var.cluster_name != ""
      error_message = "cluster_name is required when gke_mode = existing."
    }

    precondition {
      condition     = data.google_container_cluster.existing[0].networking_mode == "VPC_NATIVE"
      error_message = "The existing GKE cluster must use VPC_NATIVE networking."
    }

    precondition {
      condition     = local.existing_cluster_network == local.selected_network
      error_message = "The existing GKE cluster does not use the selected VPC."
    }

    precondition {
      condition     = local.existing_cluster_subnetwork == local.selected_subnetwork
      error_message = "The existing GKE cluster does not use the selected primary subnet."
    }

    precondition {
      condition     = local.existing_cluster_pod_range == var.pod_subnet_name
      error_message = "The existing GKE cluster Pod secondary range does not match pod_subnet_name."
    }

    precondition {
      condition     = local.existing_cluster_service_range == var.service_subnet_name
      error_message = "The existing GKE cluster Service secondary range does not match service_subnet_name."
    }

    precondition {
      condition     = local.existing_cluster_private_nodes
      error_message = "The existing GKE cluster must have private nodes enabled."
    }

    precondition {
      condition     = local.existing_cluster_workload_pool == "${var.gcp_project_id}.svc.id.goog"
      error_message = "The existing GKE cluster must use the Service Project workload pool <gcp_project_id>.svc.id.goog."
    }

    precondition {
      condition     = !var.enable_secrets_encryption || var.secrets_kms_key_name != ""
      error_message = "secrets_kms_key_name is required when validating Secrets encryption on an existing GKE cluster."
    }

    precondition {
      condition     = !var.enable_secrets_encryption || local.existing_cluster_encryption_state == "ENCRYPTED"
      error_message = "The existing GKE cluster must have application-layer Secrets encryption enabled."
    }

    precondition {
      condition     = !var.enable_secrets_encryption || local.existing_cluster_encryption_key == var.secrets_kms_key_name
      error_message = "The existing GKE cluster Secrets encryption key does not match secrets_kms_key_name."
    }
  }
}
