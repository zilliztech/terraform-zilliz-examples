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

variable "management_service_account_name" {
  description = "The name of the management service account."
  type        = string
  nullable    = false
}

variable "gke_node_service_account_name" {
  description = "The name of the gke node service account."
  type        = string
  nullable    = false
}

variable "delegate_from" {
  type = string
  description = "The service account that can impersonate the customer service account"
}

variable "gcp_zones" { 
  description = "The GCP zones for the GKE cluster."
  type        = list(string)
  default     = ["us-west1-a", "us-west1-b", "us-west1-c"]
  nullable    = false
}
