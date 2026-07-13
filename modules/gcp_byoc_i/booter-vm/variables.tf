variable "prefix_name" {
  description = "Name prefix for booter VM resources."
  type        = string
}

variable "instance_name" {
  description = "Booter VM instance name."
  type        = string
}

variable "gcp_project_id" {
  description = "Customer GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone for the booter VM."
  type        = string
}

variable "subnet_self_link" {
  description = "Subnetwork self link for the booter VM."
  type        = string
}

variable "booter_service_account_email" {
  description = "Service account email used by the booter VM."
  type        = string
}

variable "booter_image" {
  description = "Container image for the GCP-capable BYOC booter."
  type        = string
}

variable "machine_type" {
  description = "Booter VM machine type."
  type        = string
  default     = "e2-small"
}

variable "source_image" {
  description = "Booter VM source image."
  type        = string
  default     = "projects/cos-cloud/global/images/family/cos-stable"
}

variable "gke_cluster_name" {
  description = "GKE cluster name."
  type        = string
}

variable "dataplane_id" {
  description = "BYOC-I dataplane ID."
  type        = string
}

variable "agent_config" {
  description = "Cloud-agent bootstrap configuration passed to the booter container."
  type = object({
    auth_token     = string
    image          = string
    server_host    = string
    tunnel_host    = string
    endpoint_ip    = optional(string, "")
    gcp_project_id = string
  })
  sensitive = true
}

variable "labels" {
  description = "Labels to apply to the booter VM."
  type        = map(string)
  default     = {}
}

variable "resource_manager_tags" {
  description = "Resource Manager tags to bind to the booter VM."
  type        = map(string)
  default     = {}
}

variable "self_delete_ttl_seconds" {
  description = "Seconds to keep the booter VM after a successful bootstrap before self-delete."
  type        = number
  default     = 60
}

variable "failure_self_delete_ttl_seconds" {
  description = "Seconds to keep the booter VM after bootstrap failure before self-delete. Set to 0 to delete immediately."
  type        = number
  default     = 7200
}
