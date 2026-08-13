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

variable "labels" {
  description = "Labels to apply to GKE resources."
  type        = map(string)
  default     = {}
}
