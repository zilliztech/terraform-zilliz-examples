variable "bucket_name" {
  description = "GCS bucket name for the BYOC-I dataplane."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
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
