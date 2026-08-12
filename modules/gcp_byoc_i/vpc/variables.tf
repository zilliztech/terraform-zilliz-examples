variable "prefix_name" {
  description = "Name prefix for GCP BYOC-I networking resources."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project that owns the BYOC-I service resources."
  type        = string
}

variable "network_project_id" {
  description = "Project that owns the VPC and subnets. Use the service project ID for a regular VPC, or the host project ID for Shared VPC."
  type        = string
}

variable "vpc_mode" {
  description = "Whether Terraform creates the VPC or uses an existing VPC."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.vpc_mode)
    error_message = "vpc_mode must be create or existing."
  }
}

variable "subnet_mode" {
  description = "Whether Terraform creates the primary GKE subnet or uses an existing subnet."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.subnet_mode)
    error_message = "subnet_mode must be create or existing."
  }
}

variable "lb_subnet_mode" {
  description = "Whether Terraform creates the regional managed proxy subnet or uses an existing subnet."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.lb_subnet_mode)
    error_message = "lb_subnet_mode must be create or existing."
  }
}

variable "vpc_name" {
  description = "VPC network name. Defaults to <prefix_name>-vpc."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the customer VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "primary_subnet" {
  description = "Primary subnet configuration."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "pod_subnet" {
  description = "GKE pod secondary range configuration."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "service_subnet" {
  description = "GKE service secondary range configuration."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "lb_subnet" {
  description = "Regional managed proxy load balancer subnet configuration."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "labels" {
  description = "Labels to apply to supported GCP resources."
  type        = map(string)
  default     = {}
}

variable "create_cloud_nat" {
  description = "Whether Terraform creates a dedicated Cloud Router, external IP, and Cloud NAT for the primary subnet. Disable when existing networking already provides egress."
  type        = bool
  default     = true
}

variable "create_firewall_rules" {
  description = "Whether Terraform creates the BYOC-I health-check and internal firewall rules in the network project."
  type        = bool
  default     = true
}
