variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
  nullable    = false
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type    = string
  default = "us-west2"
  nullable    = false
}

variable "gcp_vpc_name" {
  description = "The VPC name of the Google Cloud Platform project."
  type        = string
  nullable    = false
  default     = "zilliz-byoc-vpc"
}

variable "gke_subnetwork_name" {
  description = "The subnetwork name of the Google Compute Engine."
  type        = string
  nullable    = false
  
}

variable "pod_subnet_range_name" {
  description = "The Pod IP CIDR range name for the subnetwork."
  type        = string
  nullable    = false
}

variable "service_subnet_range_name" {
  description = "The IP CIDR range name for the service subnet."
  type        = string
  nullable    = false
}

variable "k8s_node_groups" {
  description = "Configuration for k8s node groups including machine types, disk sizes, and instance counts."
  type = map(object({
    disk_size      = number
    min_size       = number
    max_size       = number
    spot           = bool
    instance_types = string
  }))
  default = {
    "fundamental" = {
      disk_size      = 50
      min_size       = 1
      max_size       = 1
      spot = false
      instance_types = "n2-standard-8"
    }
    "index" = {
      disk_size      = 50
      min_size       = 1
      max_size       = 50
      spot = false
      instance_types = "n2-standard-8"
    }
    "core" = {
      disk_size      = 50
      min_size       = 0
      max_size       = 6
      spot = false
      instance_types = "n2-standard-8"
    }
    "search" = {
      disk_size      = 50
      min_size       = 1
      max_size       = 6
      spot = false
      instance_types = "n2-standard-8"
    }
  }
}

variable "k8s_access_cidrs" {
  description = "The CIDR block list for the k8s endpoint access."
  type        = list(string)
  nullable    = false

  validation {
    condition     = var.k8s_access_cidrs != ""
    error_message = "variable k8s_access_cidrs cannot be empty."
  }
}

variable "gcp_zones" { 
  description = "The GCP zones for the GKE cluster."
  type        = list(string)
  default     = ["us-west2-a", "us-west2-b", "us-west2-c"]
  nullable    = false
  
}

variable "gke_node_sa" {
  description = "The GKE node service account."
  type        = string
  nullable    = false
  
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