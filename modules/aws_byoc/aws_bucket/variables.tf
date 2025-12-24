variable "region" {
  description = "The region where zilliz operations will take place. Examples are us-east-1, us-west-2, etc."
  type        = string
}

variable "s3_bucket_names" {
  type = set(string)
  default = ["milvus"]
}

variable "name" {
  description = "The name of the byoc project"
  type        = string

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