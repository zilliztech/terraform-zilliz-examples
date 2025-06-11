variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type        = string
  default     = "us-west1"
}

variable "gcp_zones" {
  description = "The GCP zones for the GKE cluster."
  type        = list(string)
  default     = null
}


variable "customer_vpc_name" {
  description = "The VPC name of the Google Cloud Platform project."
  type        = string
  default     = "zilliz-byoc-vpc"
}

variable "customer_primary_subnet_name" {
  description = "The name of the primary subnet"
  type        = string
  default     = "primary-subnet"
}

variable "customer_storage_service_account_name" {
  description = "The name of the storage service account."
  type        = string
  default     = ""
}


variable "customer_gke_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = ""
}


variable "customer_bucket_name" {
  description = "The name of the GCS bucket."
  type        = string
  default     = ""
}


variable "customer_cross-account_service_account_name" {
  description = "The name of the management service account."
  type        = string
  default     = ""
}

variable "customer_gke_node_service_account_name" {
  description = "The name of the gke node service account."
  type        = string
  default     = ""
}

variable "zilliz_service_account" {
  type        = string
  description = "The service account that can impersonate the customer service account"
}

variable "enable_private_link" {
  description = "Whether to enable private link"
  type        = bool
  default     = true
}


variable "gcp_vpc_cidr" {
  description = "The CIDR block for the customer VPC, cidr x/16"
  type        = string
}



variable "customer_primary_subnet_cidr" {
  description = "The CIDR block for the primary subnet"
  type        = string
  default     = ""
}

variable "customer_pod_subnet_name" {
  description = "The name of the pod subnet"
  type        = string
  default     = ""
}

variable "customer_pod_subnet_cidr" {
  description = "The CIDR block for the pod subnet"
  type        = string
  default     = ""
}

variable "service_subnet_name" {
  description = "The name of the service subnet"
  type        = string
  default     = ""
}

variable "customer_service_subnet_name" {
  description = "The name of the service subnet"
  type        = string
  default     = ""
}

variable "customer_service_subnet_cidr" {
  description = "The CIDR block for the service subnet"
  type        = string
  default     = ""
}

variable "customer_lb_subnet_name" {
  description = "The name of the load balancer subnet"
  type        = string
  default     = ""
}

variable "customer_lb_subnet_cidr" {
  description = "The CIDR block for the load balancer subnet"
  type        = string
  default     = ""
}
