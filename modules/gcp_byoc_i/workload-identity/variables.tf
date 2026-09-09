variable "gcp_project_id" {
  description = "Customer GCP project ID."
  type        = string
}

variable "gcp_project_number" {
  description = "Customer GCP project number, resolved outside the GKE-dependent module so IAM members remain known during planning."
  type        = string
}

variable "manage_iam" {
  description = "Whether Terraform manages the BYOC-I Workload Identity bindings."
  type        = bool
  default     = true
}

variable "gke_location" {
  description = "GKE cluster location. Regional clusters should use the region."
  type        = string
}

variable "gke_cluster_name" {
  description = "GKE cluster name. Must reference the created or existing cluster so bindings are applied after the Workload Identity pool exists."
  type        = string
}

variable "storage_sa_name" {
  description = "Fully qualified storage service account name (projects/<project>/serviceAccounts/<email>)."
  type        = string
}

variable "management_sa_name" {
  description = "Fully qualified maintenance service account name (projects/<project>/serviceAccounts/<email>)."
  type        = string
}

variable "storage_workload_identity_ksas" {
  description = "Kubernetes service accounts allowed to impersonate storage_sa via GKE Workload Identity."
  type = list(object({
    namespace = string
    name      = string
  }))
  default = []
}

variable "management_workload_identity_ksas" {
  description = "Kubernetes service accounts allowed to impersonate management_sa via GKE Workload Identity."
  type = list(object({
    namespace = string
    name      = string
  }))
  default = [
    {
      namespace = "infra"
      name      = "infra-agent-sa"
    }
  ]
}
