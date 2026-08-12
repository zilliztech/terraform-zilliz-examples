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
  }
}
