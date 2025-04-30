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
  default     = "k8s_short_cluster_name-vpc"
}

variable "gcp_vpc_cidr" {
  description = "The CIDR block for the customer VPC, cidr x/16"
  type        = string
  nullable    = false

  validation {
    condition     = var.gcp_vpc_cidr != ""
    error_message = "variable gcp_vpc_cidr cannot be empty."
  }
}

variable "gcp_zones" {
  description = "The list of GCP zones to be used."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.gcp_zones) > 0
    error_message = "variable gcp_zones must contain at least one zone."
  }
}

variable "primary_subnet" {
  description = "The configuration for the primary subnet."
  type = object({
    name = string
    cidr = string
  })
  nullable = false
}

variable "pod_subnet" {
  description = "The configuration for the pod subnet."
  type = object({
    name = string
    cidr = string
  })
  nullable = false
}

variable "service_subnet" {
  description = "The configuration for the service subnet."
  type = object({
    name = string
    cidr = string
  })
  nullable = false
}

variable "lb_subnet" {
  description = "The configuration for the load balancer subnet."
  type = object({
    name = string
    cidr = string
  })
  nullable = false
}

variable "nat_name" {
  description = "The name of the NAT gateway."
  type        = string
  nullable    = false
  default     = "nat-gateway"
  
}

variable "router_name" {
  description = "The name of the router."
  type        = string
  nullable    = false
  default     = "nat-router"
  
}