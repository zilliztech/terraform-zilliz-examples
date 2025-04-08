variable "project_id" {
  description = "The ID of the byoc project"
  type        = string
  nullable    = false
}


variable "dataplane_id" {
  description = "The ID of the data plane"
  type        = string
  nullable    = false
}

variable "vpc_cidr" {
  description = "If the VPC is created and managed by this terraform this will be the CIDR block of that VPC."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "If the VPC is created and managed outside of this terraform the ID of the VPC should be provided and then VPC creation will be skipped."
  type        = string
  default     = ""
}

variable "private_subnets" {
  description = "List of private subnets if created externally to this terraform."
  type        = list(string)
  default     = []
}

variable "sg_id" {
  description = "ID of security group if if created externally to this terraform."
  type        = string
  default     = ""
}

variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Specified name of EKS cluster"
  type        = string
  default     = ""
}

variable "bucket_id" {
  description = "ID of bucket if created externally to this terraform"
  type        = string
  default     = ""
}

variable "ecr" {
  description = "Specified ECR"
  type        = string
  default     = ""
}

variable "storage_role_name" {
  description = "Specified name of the storage role for S3 access"
  type        = string
  default     = ""
}

variable "eks_addon_role_name" {
  description = "Specified name of the eks addon role for S3 access"
  type        = string
  default     = ""
}

variable "eks_role_name" {
  description = "Specified name of EKS cluster role"
  type        = string
  default     = ""
}

variable "maintenance_role_name" {
  description = "Specified name of the maintenance role for cluster administration"
  type        = string
  default     = ""
}

