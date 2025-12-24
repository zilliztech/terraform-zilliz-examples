variable "prefix_name" {
  description = "Prefix name"
  type        = string
}
variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "customer_bucket_name" {
  description = "Bucket name"
  type        = string
  default     = ""
}

variable "enable_s3_kms" {
  description = "Enable S3 KMS usage"
  type        = bool
  default     = false
}

variable "s3_kms_key_arn" {
  description = "The ARN of the KMS key to use for S3 encryption"
  type        = string
  default     = ""
}