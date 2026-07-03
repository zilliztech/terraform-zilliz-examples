variable "prefix_name" {
  description = "Name prefix for GCP BYOC-I networking resources."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
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
