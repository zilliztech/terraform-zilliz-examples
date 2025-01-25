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

variable "eks_oidc_url" {
  description = "The OIDC URL for the EKS cluster"
  type        = string
  default     = "eks_oidc_url"
}
