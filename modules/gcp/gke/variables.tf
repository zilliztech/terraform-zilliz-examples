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

variable "gcp_subnetwork_name" {
  description = "The subnetwork name of the Google Cloud Platform project."
  type        = string
  nullable    = false
  default     = "zilliz-byoc-subnet"
  
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

variable "k8s_short_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  nullable    = false

  validation {
    condition     = var.k8s_short_cluster_name != ""
    error_message = "variable k8s_short_cluster_name cannot be empty."
  }
}

variable "k8s_node_groups" {
  description = "Configuration for k8s node groups including machine types, disk sizes, and instance counts."
  type = map(object({
    disk_size      = number
    min_size       = number
    max_size       = number
    # desired_size   = number
    instance_types = string
  }))
  default = {
    "fundamentals" = {
      disk_size      = 50
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = "n2-standard-8"
    }
    "index" = {
      disk_size      = 50
      min_size       = 1
      max_size       = 50
      instance_types = "n2-standard-8"
    }
    "core" = {
      disk_size      = 50
      min_size       = 0
      max_size       = 6
      instance_types = "n2-standard-8"
    }
    "search" = {
      disk_size      = 50
      min_size       = 1
      max_size       = 6
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

variable "biz_sa_email" {
  description = "The email address of the service account for the business logic."
  type        = string
  nullable    = false
  
}

variable "buckets" {
  type = set(string)
  default = [ "bp", "loki" ]
  
}

# variable "states_dir" {
#   description = "The directory for the byoc states files."
#   type        = string
#   nullable    = false
# }


# app's var
variable "csp" {
  description = "The cloud service provider."
  type        = string
  nullable    = false

  default = "gcp"
}

variable "registrykey" {
  description = "The registry key."
  type        = string
  nullable    = false

  default = ""

}