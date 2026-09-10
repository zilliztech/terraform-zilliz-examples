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

  validation {
    condition     = length(var.gcp_zones) > 0 && length(distinct(var.gcp_zones)) == length(var.gcp_zones)
    error_message = "gcp_zones must contain at least one zone and no duplicates."
  }
}

variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
}

variable "gke_mode" {
  description = "GKE cluster lifecycle mode. create provisions the cluster and node pools; existing reads an existing cluster and only provisions BYOC-I node pools."
  type        = string
  default     = "create"

  validation {
    condition     = contains(["create", "existing"], var.gke_mode)
    error_message = "gke_mode must be create or existing."
  }
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
  description = "Service secondary range name. Use an empty string for GKE-managed Services (GKE Standard 1.29+)."
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

variable "enable_private_endpoint" {
  description = "Whether the GKE control plane is accessible only through its private endpoint."
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Whether GKE nodes use internal IP addresses only."
  type        = bool
  default     = true
}

variable "enable_ip_alias" {
  description = "Whether to use VPC-native alias IP networking."
  type        = bool
  default     = true
}

variable "workload_pool" {
  description = "GKE Workload Identity pool. Leave empty to use <gcp_project_id>.svc.id.goog."
  type        = string
  default     = ""
}

variable "node_initial_count" {
  description = "Optional initial node count PER ZONE override applied to every BYOC-I node pool. Leave null to divide the node-group desired/minimum total by the number of zones, rounding up."
  type        = number
  default     = null
  validation {
    condition = var.node_initial_count == null ? true : (
      var.node_initial_count >= 0 && floor(var.node_initial_count) == var.node_initial_count
    )
    error_message = "node_initial_count must be null or a non-negative integer."
  }
}

variable "node_disk_size_gb" {
  description = "Optional boot disk size override in GiB applied to every BYOC-I node pool. Leave null to use the node-group quota with a 100 GiB minimum."
  type        = number
  default     = null
  validation {
    condition = var.node_disk_size_gb == null ? true : (
      var.node_disk_size_gb > 0 && floor(var.node_disk_size_gb) == var.node_disk_size_gb
    )
    error_message = "node_disk_size_gb must be null or a positive integer."
  }
}

variable "node_image_type" {
  description = "GKE node image type applied to every BYOC-I node pool."
  type        = string
  default     = "COS_CONTAINERD"
  validation {
    condition     = trimspace(var.node_image_type) != ""
    error_message = "node_image_type must not be empty."
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

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "UNSPECIFIED"
  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE", "EXTENDED"], upper(var.release_channel))
    error_message = "release_channel must be UNSPECIFIED, RAPID, REGULAR, STABLE, or EXTENDED."
  }
}

variable "binary_authorization_evaluation_mode" {
  description = "Binary Authorization evaluation mode. Leave empty to omit the cluster configuration."
  type        = string
  default     = ""
  validation {
    condition     = contains(["", "DISABLED", "PROJECT_SINGLETON_POLICY_ENFORCE"], upper(var.binary_authorization_evaluation_mode))
    error_message = "binary_authorization_evaluation_mode must be empty, DISABLED, or PROJECT_SINGLETON_POLICY_ENFORCE."
  }
}

variable "enable_identity_service" {
  description = "Whether to enable GKE Identity Service."
  type        = bool
  default     = false
}

variable "enable_intranode_visibility" {
  description = "Whether to enable intra-node visibility."
  type        = bool
  default     = false
}

variable "node_enable_secure_boot" {
  description = "Whether to enable Secure Boot on GKE nodes."
  type        = bool
  default     = false
}

variable "node_enable_integrity_monitoring" {
  description = "Whether to enable integrity monitoring on GKE nodes."
  type        = bool
  default     = true
}

variable "node_auto_repair" {
  description = "Whether to enable automatic repair for GKE node pools."
  type        = bool
  default     = true
}

variable "node_auto_upgrade" {
  description = "Whether to enable automatic upgrades for GKE node pools."
  type        = bool
  default     = false
}

variable "enable_secrets_encryption" {
  description = "Enable GKE application-layer encryption for Kubernetes Secrets stored in etcd."
  type        = bool
  default     = false
}

variable "secrets_kms_key_name" {
  description = "Existing Cloud KMS key used for GKE application-layer Secrets encryption. Leave empty to let Terraform create a regional key when enable_secrets_encryption is true."
  type        = string
  default     = ""

  validation {
    condition     = var.secrets_kms_key_name == "" || can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.secrets_kms_key_name))
    error_message = "secrets_kms_key_name must be empty or a full Cloud KMS crypto key resource name."
  }
}

variable "grant_secrets_kms_key_iam" {
  description = "Whether Terraform grants the GKE service agent roles/cloudkms.cryptoKeyEncrypterDecrypter on an existing secrets_kms_key_name. Terraform-created keys are always granted."
  type        = bool
  default     = true
}

variable "boot_disk_kms_key_name" {
  description = "Cloud KMS key for GKE node boot disks. Leave empty to reuse secrets_kms_key_name when secrets encryption is enabled. Required under gcp.restrictNonCmekServices."
  type        = string
  default     = ""

  validation {
    condition     = var.boot_disk_kms_key_name == "" || can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.boot_disk_kms_key_name))
    error_message = "boot_disk_kms_key_name must be empty or a full Cloud KMS crypto key resource name."
  }
}

variable "labels" {
  description = "Labels to apply to GKE resources."
  type        = map(string)
  default     = {}
}
