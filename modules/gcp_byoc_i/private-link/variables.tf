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

variable "enable_private_dns" {
  description = "Whether to create Cloud DNS private records for PSC service hosts."
  type        = bool
  default     = true
}

variable "private_dns_zone_name" {
  description = "Optional Cloud DNS managed zone name for PSC private records."
  type        = string
  default     = ""
}

variable "private_dns_domain" {
  description = "Cloud DNS private zone DNS name for PSC service hosts."
  type        = string
  default     = ""
}

variable "private_dns_record_names" {
  description = "PSC private DNS A record FQDNs that resolve to the PSC endpoint IP."
  type        = list(string)
  default     = []
}
