variable "gcp_project_id" {
  description = "Customer GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the regional GKE cluster."
  type        = string
}

variable "gcp_zones" {
  description = "GCP zones used as GKE node locations."
  type        = list(string)
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
}

variable "network_self_link" {
  description = "VPC network self link."
  type        = string
}

variable "primary_subnet_self_link" {
  description = "Primary subnet self link."
  type        = string
}

variable "pod_subnet_name" {
  description = "Pod secondary range name."
  type        = string
}

variable "service_subnet_name" {
  description = "Service secondary range name."
  type        = string
}

variable "gke_node_sa_email" {
  description = "GKE node service account email."
  type        = string
}

variable "k8s_node_groups" {
  description = "Node group quota map from zillizcloud_byoc_i_project_settings."
  type = map(object({
    disk_size      = number
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = string
    capacity_type  = string
  }))
}

variable "kubernetes_version" {
  description = "Optional GKE Kubernetes version."
  type        = string
  default     = null
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the private GKE control plane."
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(cidrhost(var.master_ipv4_cidr_block, 0)) && tonumber(split("/", var.master_ipv4_cidr_block)[1]) == 28
    error_message = "master_ipv4_cidr_block must be a valid /28 CIDR block."
  }
}

variable "master_authorized_networks" {
  description = "CIDR blocks authorized to access the private GKE control plane."
  type = list(object({
    cidr_block   = string
    display_name = optional(string, "byoc-primary-subnet")
  }))
  default = []
}

variable "deletion_protection" {
  description = "Whether to enable GKE deletion protection."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to GKE resources."
  type        = map(string)
  default     = {}
}
