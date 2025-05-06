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

variable "gcp_vpc_cidr" {
  description = "The CIDR block for the customer VPC, cidr x/16"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_zones" {
  description = "The list of GCP zones to be used."
  type        = list(string)
  default     = ["us-west2-a", "us-west2-b", "us-west2-c"]
}



variable "primary_subnet_name" {
  description = "The name of the primary subnet"
  type        = string
  default     = "primary-subnet"
}

variable "primary_subnet_cidr" {
  description = "The CIDR block for the primary subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "pod_subnet_name" {
  description = "The name of the pod subnet"
  type        = string
  default     = "pod-subnet"
}

variable "pod_subnet_cidr" {
  description = "The CIDR block for the pod subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "service_subnet_name" {
  description = "The name of the service subnet"
  type        = string
  default     = "service-subnet"
}

variable "service_subnet_cidr" {
  description = "The CIDR block for the service subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "lb_subnet_name" {
  description = "The name of the load balancer subnet"
  type        = string
  default     = "lb-subnet"
}

variable "lb_subnet_cidr" {
  description = "The CIDR block for the load balancer subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "storage_bucket_name" {
  description = "The name of the GCS bucket."
  type        = string
}
variable "buckets" {
  description = "The list of buckets to create"
  type        = set(string)
  default     = ["bp", "loki"]
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