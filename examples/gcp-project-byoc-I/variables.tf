variable "project_id" {
  description = "Zilliz Cloud BYOC project ID."
  type        = string
  nullable    = false
}

variable "dataplane_id" {
  description = "Zilliz Cloud BYOC-I dataplane ID."
  type        = string
  nullable    = false
}

variable "gcp_project_id" {
  description = "Customer GCP project ID."
  type        = string
  nullable    = false
}

variable "booter_image" {
  description = "Optional container image for the GCP-capable BYOC-I booter. Defaults by env when unset."
  type        = string
  default     = ""
}

variable "gcp_zones" {
  description = "GCP zones used by GKE node pools. Defaults to <settings region>-a/b/c."
  type        = list(string)
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the customer VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "customer_vpc_name" {
  description = "Optional customer VPC name."
  type        = string
  default     = ""
}

variable "customer_gke_cluster_name" {
  description = "Optional customer GKE cluster name."
  type        = string
  default     = ""
}

variable "customer_bucket_name" {
  description = "Optional customer GCS bucket name."
  type        = string
  default     = ""
}

variable "customer_gke_node_service_account_name" {
  description = "Optional GKE node service account account_id."
  type        = string
  default     = ""
}

variable "customer_management_service_account_name" {
  description = "Optional maintenance service account account_id."
  type        = string
  default     = ""
}

variable "customer_storage_service_account_name" {
  description = "Optional storage service account account_id."
  type        = string
  default     = ""
}

variable "customer_booter_service_account_name" {
  description = "Optional booter VM service account account_id."
  type        = string
  default     = ""
}

variable "primary_subnet" {
  description = "Optional primary subnet override."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "pod_subnet" {
  description = "Optional GKE pod secondary range override."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "service_subnet" {
  description = "Optional GKE service secondary range override."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "lb_subnet" {
  description = "Optional regional managed proxy subnet override."
  type = object({
    name = optional(string, "")
    cidr = optional(string, "")
  })
  default = {}
}

variable "enable_private_link" {
  description = "Whether to create a GCP Private Service Connect endpoint when BYOC-I settings allow it."
  type        = bool
  default     = true
}

variable "gcp_psc_service_attachment_id" {
  description = "Optional PSC service attachment ID. Defaults by environment and region when unset."
  type        = string
  default     = ""
}

variable "enable_private_dns" {
  description = "Whether to create Cloud DNS private records for Private Service Connect service hosts."
  type        = bool
  default     = true
}

variable "gcp_psc_private_dns_domain" {
  description = "Optional Cloud DNS private zone DNS name for PSC service hosts. Defaults to gcp-<region>.byoc.<env_domain>."
  type        = string
  default     = ""
}

variable "gcp_psc_private_dns_record_names" {
  description = "Optional PSC private DNS A record FQDNs. Defaults to cloud-tunnel and cloud-open-api under the PSC private DNS domain."
  type        = list(string)
  default     = []
}

variable "booter_machine_type" {
  description = "Booter VM machine type."
  type        = string
  default     = "e2-small"
}

variable "booter_failure_self_delete_ttl_seconds" {
  description = "Seconds to keep the booter VM after bootstrap failure before self-delete. Set to 0 to delete immediately."
  type        = number
  default     = 7200
}

variable "booter_print_serial_logs_on_apply" {
  description = "Print booter VM serial console logs during terraform apply for troubleshooting. Requires gcloud on the Terraform runner."
  type        = bool
  default     = false
}

variable "agent_server_host" {
  description = "Optional cloud-agent tunnel server host override."
  type        = string
  default     = ""
}

variable "agent_tunnel_host" {
  description = "Optional cloud-agent Kubernetes tunnel host override."
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name. UAT uses cloud-uat3.zilliz.com, all other values use cloud.zilliz.com."
  type        = string
  default     = "Production"
}

variable "kubernetes_version" {
  description = "Optional GKE Kubernetes version."
  type        = string
  default     = null
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the private GKE control plane. Use a unique /28 when peering multiple BYOC-I VPCs."
  type        = string
  default     = "172.16.0.0/28"
}

variable "enable_direct_mig_resize" {
  description = "Enable direct GKE-managed MIG resize permissions for maintenance_sa. Required for node group scale operations."
  type        = bool
  default     = true
}

variable "enable_resource_manager_tags" {
  description = "Enable Resource Manager tags for BYOC-I resources and use tag-scoped booter self-delete permissions."
  type        = bool
  default     = true
}

variable "vendor_tag_key_id" {
  description = "Optional pre-created Resource Manager tag key ID, for example tagKeys/123. Leave empty to let Terraform create a per-dataplane tag key."
  type        = string
  default     = ""

  validation {
    condition     = var.vendor_tag_key_id == "" || can(regex("^tagKeys/[0-9]+$", var.vendor_tag_key_id))
    error_message = "vendor_tag_key_id must be empty or use the format tagKeys/<numeric-id>."
  }
}

variable "vendor_tag_value_id" {
  description = "Optional pre-created Resource Manager tag value ID, for example tagValues/456. Leave empty to let Terraform create a per-dataplane booter tag value."
  type        = string
  default     = ""

  validation {
    condition     = var.vendor_tag_value_id == "" || can(regex("^tagValues/[0-9]+$", var.vendor_tag_value_id))
    error_message = "vendor_tag_value_id must be empty or use the format tagValues/<numeric-id>."
  }
}

variable "bucket_force_destroy" {
  description = "Whether to force destroy non-empty GCS buckets."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to supported GCP resources."
  type        = map(string)
  default     = {}
}
