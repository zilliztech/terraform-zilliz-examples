variable "prefix_name" {
  description = "Name prefix for PSC resources."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
}

variable "vpc_name" {
  description = "VPC network name."
  type        = string
}

variable "subnet_name" {
  description = "Subnet name where the PSC endpoint IP is allocated."
  type        = string
}

variable "service_attachment_id" {
  description = "Optional Zilliz BYOC PSC service attachment ID. Defaults to modules/conf.yaml for supported regions."
  type        = string
  default     = ""
}
