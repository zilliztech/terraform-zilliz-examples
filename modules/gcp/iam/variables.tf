variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
  nullable    = false
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type    = string
  default = "us-west1"
  nullable    = false
}

variable "create_storage_sa" {
  description = "Whether to create the storage service account."
  type        = bool
  default     = false
}

variable "storage_service_account_name" {
  description = "The name of the storage service account."
  type        = string
  nullable    = false
}

variable "storage_bucket_name" {
  description = "The name of the storage bucket."
  type        = string
  nullable    = false

  validation {
    condition     = var.storage_bucket_name != ""
    error_message = "variable storage_bucket_name cannot be empty."
  }
  
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  nullable    = false

  validation {
    condition     = var.gke_cluster_name != ""
    error_message = "variable gke_cluster_name cannot be empty."
  }
  
}