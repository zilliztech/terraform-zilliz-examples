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

variable "customer_vpc_id" {
  description = "The ID of the customer VPC"
  type        = string
  default     = ""

}

variable "customer_security_group_id" {
  description = "The ID of the security group for the customer VPC"
  type        = string
  default     = ""
}

variable "customer_private_subnet_ids" {
  description = "The IDs of the private subnets for the customer VPC"
  type        = list(string)
  default     = []
}

variable "customer_eks_control_plane_private_subnet_ids" {
  description = "The IDs of the private subnets for the customer's EKS control plane, must be in at least two different availability zones. Default to use customer_private_subnet_ids if not provided"
  type        = list(string)
  default     = []
}


variable "enable_private_link" {
  description = "Enable private link for the byoc project"
  type        = bool
  default = null
  nullable = true
}

variable "customer_ecr" {
  description = "Customer ECR configuration containing account ID, region, and prefix"
  type = object({
    ecr_account_id = string
    ecr_region     = string
    ecr_prefix     = string
    }
  )
  validation {
    condition     = var.customer_ecr.ecr_prefix != "" && var.customer_ecr.ecr_account_id != "" && var.customer_ecr.ecr_region != ""
    error_message = "ECR prefix, account ID and region cannot be empty"
  }

  default = {
    ecr_account_id = "965570967084"
    ecr_region     = "us-west-2"
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
