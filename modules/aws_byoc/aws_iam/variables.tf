variable "name" {
  description = "The name of the byoc project"
  type        = string

}

variable "ExternalId" {
  description = "The external ID for the role"
  type        = string

}

variable "bucketName" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "federated_principal" {
  description = "The federated principal ARN for OIDC provider"
  type        = string
  default     = "arn:aws:iam::accountid:oidc-provider/eks_oidc_url"
}

# https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
variable "enable_ebs_kms" {
  description = "Enable EBS KMS usage"
  type        = bool
  default     = false
}

variable "ebs_kms_key_arn" {
  description = "The ARN of the KMS key to use for EBS encryption"
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
