resource "terraform_data" "gke_input_validation" {
  input = {
    gke_mode                  = var.gke_mode
    customer_gke_cluster_name = var.customer_gke_cluster_name
  }

  lifecycle {
    precondition {
      condition     = var.gke_mode != "existing" || var.customer_gke_cluster_name != ""
      error_message = "customer_gke_cluster_name is required when gke_mode = existing."
    }

    precondition {
      condition     = var.gcp_region == "" || var.gcp_region == local.dataplane_gcp_region
      error_message = "gcp_region must match the region configured for the Zilliz Cloud dataplane."
    }

    precondition {
      condition     = var.gke_workload_pool == "" || var.gke_workload_pool == "${var.gcp_project_id}.svc.id.goog"
      error_message = "gke_workload_pool must be empty or <gcp_project_id>.svc.id.goog."
    }
  }
}

resource "terraform_data" "bucket_input_validation" {
  lifecycle {
    precondition {
      condition     = var.bucket_mode != "existing" || var.customer_bucket_name != ""
      error_message = "customer_bucket_name is required when bucket_mode = existing."
    }

    precondition {
      condition     = var.bucket_mode != "existing" || !var.enable_gcs_kms
      error_message = "enable_gcs_kms must be false when bucket_mode = existing because Terraform does not modify an existing bucket."
    }
  }
}
