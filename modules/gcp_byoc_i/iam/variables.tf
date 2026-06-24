variable "gcp_project_id" {
  description = "Customer GCP project ID."
  type        = string
}

variable "prefix_name" {
  description = "Name prefix for service accounts and custom roles."
  type        = string
}

variable "gke_location" {
  description = "GKE cluster location. Regional clusters should use the region."
  type        = string
}

variable "gke_cluster_name" {
  description = "GKE cluster name."
  type        = string
}

variable "storage_bucket_name" {
  description = "GCS bucket name used by the BYOC-I dataplane."
  type        = string
}

variable "zilliz_byoc_service_account_email" {
  description = "Zilliz Cloud BYOC service account email allowed to impersonate the maintenance service account."
  type        = string
}

variable "gke_node_service_account_name" {
  description = "GKE node service account account_id. Defaults to <prefix_name>-node."
  type        = string
  default     = ""
}

variable "management_service_account_name" {
  description = "Maintenance service account account_id. Defaults to <prefix_name>-maintenance."
  type        = string
  default     = ""
}

variable "storage_service_account_name" {
  description = "Storage service account account_id. Defaults to <prefix_name>-storage."
  type        = string
  default     = ""
}

variable "booter_service_account_name" {
  description = "Booter VM service account account_id. Defaults to <prefix_name>-booter."
  type        = string
  default     = ""
}

variable "storage_workload_identity_ksas" {
  description = "Kubernetes service accounts allowed to impersonate storage_sa via GKE Workload Identity."
  type = list(object({
    namespace = string
    name      = string
  }))
  default = []
}

variable "enable_direct_mig_resize" {
  description = "Enable optional direct GKE-managed MIG resize permissions for maintenance_sa."
  type        = bool
  default     = false
}

variable "booter_instance_name" {
  description = "Booter VM instance name used to scope fallback self-delete permissions."
  type        = string
}

variable "booter_zone" {
  description = "Booter VM zone used to scope fallback self-delete operation permissions."
  type        = string
}

variable "enable_resource_manager_tags" {
  description = "Whether booter self-delete permissions use Resource Manager tag conditions."
  type        = bool
  default     = true
}

variable "vendor_tag_key_id" {
  description = "Resource Manager tag key ID used by booter self-delete IAM condition."
  type        = string
  default     = ""
}

variable "vendor_tag_value_id" {
  description = "Resource Manager tag value ID used by booter self-delete IAM condition."
  type        = string
  default     = ""
}
