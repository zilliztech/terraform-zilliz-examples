variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type        = string
  default     = "us-west2"
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
