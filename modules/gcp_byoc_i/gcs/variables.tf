variable "bucket_name" {
  description = "GCS bucket name for the BYOC-I dataplane."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
}

variable "gcp_project_id" {
  description = "Customer GCP project ID."
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Whether to force destroy non-empty buckets."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "enable_gcs_kms" {
  description = "Enable Cloud KMS customer-managed encryption key for the GCS bucket."
  type        = bool
  default     = false
}

variable "gcs_kms_key_name" {
  description = "Existing Cloud KMS key resource name used as the default GCS bucket encryption key. Leave empty to let Terraform create one when enable_gcs_kms is true."
  type        = string
  default     = ""
}

variable "grant_gcs_kms_key_iam" {
  description = "Whether Terraform should grant the Cloud Storage service agent roles/cloudkms.cryptoKeyEncrypterDecrypter on an existing gcs_kms_key_name. Terraform-created keys are always granted."
  type        = bool
  default     = true
}
