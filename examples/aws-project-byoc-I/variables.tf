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
  description = "The CIDR block for the customer VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "customer_pod_subnet_ids" {
  description = "The IDs of the pod subnets for the customer VPC"
  type        = list(string)
  default     = []
}

variable "customer_vpc_id" {
  description = "The ID of the customer VPC"
  type        = string
  default     = ""
}

variable "customer_node_security_group_ids" {
  description = "security group IDs for the node group"
  type        = list(string)
  default     = []
}

variable "customer_private_link_security_group_ids" {
  description = "security group IDs for the private link"
  type        = list(string)
  default     = []
}

variable "create_private_link_security_group" {
  description = "Whether to create a new security group for the private link endpoint"
  type        = bool
  default     = false
}

variable "private_link_security_group_name" {
  description = "The name of the security group for the private link, if create_private_link_security_group is true"
  type        = string
  default     = ""
}

variable "customer_private_subnet_ids" {
  description = "The IDs of the private subnets for the customer VPC"
  type        = list(string)
  default     = []
}

variable "customer_private_link_subnet_ids" {
  description = "The IDs of the private subnets for the private link endpoint. If not provided, will use customer_private_subnet_ids or default subnets"
  type        = list(string)
  default     = []
}

variable "customer_eks_control_plane_private_subnet_ids" {
  description = "The IDs of the private subnets for the customer's EKS control plane, must be in at least two different availability zones. Default to use customer_private_subnet_ids if not provided"
  type        = list(string)
  default     = []
}

variable "customer_ecr" {
  description = "Customer ECR configuration containing account ID, region, and prefix"
  type = object({
    ecr_account_id = string
    ecr_region     = string
    ecr_prefix     = string
    }
  )

  default = {
    ecr_account_id = "965570967084"
    ecr_region     = ""
    ecr_prefix     = "zilliz-byoc"
  }
}

variable "customer_bucket_name" {
  description = "The name of the customer bucket"
  type        = string
  default     = ""
}

variable "customer_eks_cluster_name" {
  description = "The name of the customer EKS cluster"
  type        = string
  default     = ""
}

variable "customer_storage_role_name" {
  description = "The name of the customer storage role for S3 access"
  type        = string
  default     = ""
}

variable "customer_eks_addon_role_name" {
  description = "The name of the customer EKS addon role for S3 access"
  type        = string
  default     = ""
}

variable "customer_eks_role_name" {
  description = "The name of the customer EKS cluster role"
  type        = string
  default     = ""
}

variable "customer_maintenance_role_name" {
  description = "The name of the customer maintenance role for cluster administration"
  type        = string
  default     = ""
}

variable "custom_tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_endpoint" {
  description = "Enable endpoint"
  type        = bool
  default     = false
}


variable "enable_manual_private_link" {
  description = "Enable manual private link creation"
  type        = bool
  default     = false
}

variable "booter" {
  description = "Booter configuration including account ID, region, prefix, image"
  type = object({
    account_id = optional(string, "")
    region     = optional(string, "")
    prefix     = optional(string, "")
    image      = optional(string, "")
  })
  default = {
    account_id = "306787409409"
    region     = "us-west-2"
    prefix     = "zilliz-byoc"
    image      = "infra/uat-byoc-booter"
  }
}

variable "minimal_roles" {
  description = "Minimal role configuration for EKS role separation and customization"
  type = object({
    enabled = optional(bool, false)
    # Cluster role configuration
    cluster_role = optional(object({
      name    = optional(string, "")
      use_existing_arn = optional(string, "")  # Use existing role by ARN
    }), {})
    # Node role configuration  
    node_role = optional(object({
      name    = optional(string, "")
      use_existing_arn = optional(string, "")  # Use existing role by ARN
    }), {})
  })
  default = {
    enabled = false
  }
  
  validation {
    condition = alltrue([
      length(var.minimal_roles.cluster_role.use_existing_arn) == 0 || can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$", var.minimal_roles.cluster_role.use_existing_arn)),
      length(var.minimal_roles.node_role.use_existing_arn) == 0 || can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$", var.minimal_roles.node_role.use_existing_arn))
    ])
    error_message = "use_existing_arn must be a valid IAM role ARN format: arn:aws:iam::ACCOUNT:role/ROLE_NAME"
  }
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
