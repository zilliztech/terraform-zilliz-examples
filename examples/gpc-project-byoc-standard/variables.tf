variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type        = string
  default     = "us-west2"
}

variable "gcp_zones" { 
  description = "The GCP zones for the GKE cluster."
  type        = list(string)
  default     = ["us-west1-a", "us-west1-b", "us-west1-c"]
  nullable    = false
}


variable "gcp_vpc_name" {
  description = "The VPC name of the Google Cloud Platform project."
  type        = string
  default     = "zilliz-byoc-vpc"
}

variable "primary_subnet_name" {
  description = "The name of the primary subnet"
  type        = string
  default     = "primary-subnet"
}
variable "create_storage_sa" {
  description = "Whether to create the storage service account."
  type        = bool
  default     = true
}

variable "storage_service_account_name" {
  description = "The name of the storage service account."
  type        = string
  default     = "storage-sa"
}


variable "k8s_short_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}


variable "storage_bucket_name" {
  description = "The name of the GCS bucket."
  type        = string
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
  type        = string
  description = "The service account that can impersonate the customer service account"
}
