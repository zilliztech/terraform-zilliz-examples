variable "aws_region" {
  description = "The region where zilliz operations will take place. Examples are us-east-1, us-west-2, etc."
  type        = string
  nullable    = false
}

variable "customer_vpc_id" {
  description = "The ID of the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.customer_vpc_id != ""
    error_message = "variable customer_vpc_id cannot be empty."
  }
}

variable "customer_security_group_id" {
  description = "The ID of the security group for the customer VPC"
  type        = string
  nullable    = false

  validation {
    condition     = var.customer_security_group_id != ""
    error_message = "variable customer_security_group_id cannot be empty."
  }
}

variable "customer_private_subnet_ids" {
  description = "The IDs of the private subnets for the customer VPC"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.customer_private_subnet_ids) > 0
    error_message = "variable customer_private_subnet_ids cannot be empty."
  }
}

variable "customer_eks_control_plane_private_subnet_ids" {
  description = "The IDs of the private subnets for the customer's EKS control plane, default to use customer_private_subnet_ids if not provided"
  type        = list(string)
  default     = []
}

variable "name" {
  description = "The name of the byoc project"
  type        = string
  nullable    = false

  validation {
    condition     = var.name != ""
    error_message = "variable name cannot be empty."
  }
}

variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default     = false
}

variable "customer_ecr" {
  description = "Customer ECR configuration containing account ID, region, and prefix"
  type = object({
    ecr_account_id = string
    ecr_region     = string
    ecr_prefix     = string
  })
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

variable "core_instance_type" {
  description = "Instance type used for the core virtual machine, which hosts Milvus Operators, Zilliz Cloud Agent, and Milvus dependencies, such as Prometheus, Etcd, Pulsar, etc. "
  type        = string
  default     = "m6i.2xlarge"
}

variable "fundamental_instance_type" {
  description = "Instance type used for the fundamental virtual machine, which hosts Milvus components other than the query nodes, including the proxy, datanode, index pool, and coordinators. "
  type        = string
  default     = "m6i.2xlarge"
}

variable "search_instance_type" {
  description = "Instance type used for the search virtual machine, which hosts the query nodes."
  type        = string
  default     = "m6id.4xlarge"
}