locals {
  storage_cluster_workload_identity_member = "principalSet://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.gcp_project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gke_location}/clusters/${var.gke_cluster_name}"
}
