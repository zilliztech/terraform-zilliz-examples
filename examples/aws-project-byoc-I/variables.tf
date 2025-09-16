variable "project_id" {
  description = <<EOF
    The ID of the Zilliz BYOC project.
    EOF
  type        = string
  nullable    = false
}

variable "dataplane_id" {
  description = <<EOF
    The ID of the Zilliz data plane.
    EOF
  type        = string
  nullable    = false
}

variable "vpc_cidr" {
  description = <<EOF
    The CIDR block for new VPC creation. Only used when customer_vpc_id is empty (creating new VPC). 
    Ignored when using existing customer VPC.
    EOF
  type        = string
  default     = "10.0.0.0/16"
}

variable "customer_pod_subnet_ids" {
  description = <<EOF
    Additional subnet IDs specifically for Kubernetes pod networking (optional). 
    Only used when customer provides existing VPC with dedicated pod subnets.
    EOF
  type        = list(string)
  default     = []
}

variable "customer_vpc_id" {
  description = <<EOF
    The ID of an existing customer VPC. Leave empty to create a new VPC, 
    or provide existing VPC ID to use customer-managed VPC infrastructure.
    EOF
  type        = string
  default     = ""
}

variable "customer_security_group_id" {
  description = <<EOF
    The ID of the security group for the customer VPC. Required when customer_vpc_id is provided. 
    Used for EKS cluster and worker node security group configuration.
    EOF
  type        = string
  default     = ""
}

variable "customer_private_subnet_ids" {
  description = <<EOF
    The IDs of private subnets in the customer VPC. Required when customer_vpc_id is provided. 
    Used for EKS worker nodes and database components.
    EOF
  type        = list(string)
  default     = []
}

variable "customer_eks_control_plane_private_subnet_ids" {
  description = <<EOF
    The IDs of private subnets for EKS control plane ENIs (Elastic Network Interfaces). 
    Controls which subnets the EKS API server endpoint can be accessed from. 
    Must be in at least two different availability zones when provided. 
    Defaults to customer_private_subnet_ids if not provided.
    EOF
  type        = list(string)
  default     = []
}



variable "customer_ecr" {
  description = <<EOF
    Customer ECR (Elastic Container Registry) configuration for container management. 
    Contains EKS cluster details and customer ECR registry information for container image storage and deployment.
    EOF
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
  description = <<EOF
    Custom name for the S3 bucket used for storing Zilliz data, backups, and operational logs. 
    If empty, uses '{local.prefix_name}-milvus' as bucket name.
    EOF
  type        = string
  default     = ""
}

variable "customer_eks_cluster_name" {
  description = <<EOF
    Custom name for the EKS cluster. 
    If empty, uses '{local.prefix_name}' as EKS cluster name.
    EOF
  type        = string
  default     = ""
}

variable "customer_storage_role_name" {
  description = <<EOF
    Custom name for the IAM role that allows EKS to manage EBS volumes and other storage resources for stateful workloads.
     If empty, uses '{local.prefix_name}-storage-role' as role name.
    EOF
  type        = string
  default     = ""
}

variable "customer_eks_addon_role_name" {
  description = <<EOF
    Custom name for the IAM role for EKS add-ons (AWS Load Balancer Controller, EBS CSI driver, etc.).
     Enables EKS add-ons to interact with AWS services on behalf of the cluster. 
     If empty, uses '{local.prefix_name}-addon-role' as role name.
    EOF
  type        = string
  default     = ""
}

variable "customer_eks_role_name" {
  description = <<EOF
    Custom name for the IAM role for EKS cluster service account. 
    Provides necessary permissions for EKS cluster operations and AWS service integration. 
    If empty, uses '{local.prefix_name}-eks-role' as role name.
    EOF
  type        = string
  default     = ""
}

variable "customer_maintenance_role_name" {
  description = <<EOF
    Custom name for the IAM role used for automated cluster patching, updates, and maintenance tasks. 
    If empty, uses '{local.prefix_name}-maintenance-role' as role name.
    EOF
  type        = string
  default     = ""
}

variable "custom_tags" {
  description = <<EOF
    Custom tags to apply to all created resources (EKS cluster, S3 bucket, IAM roles, VPC PrivateLink endpoint). 
    Used for resource organization, cost tracking, and compliance.
    EOF
  type        = map(string)
  default     = {}
}

variable "enable_endpoint" {
  description = <<EOF
    Flag to enable/disable additional network endpoint creation. Controls whether additional network endpoints should be provisioned.
    EOF
  type        = bool
  default     = false
}

variable "enable_manual_private_link" {
  description = <<EOF
    Flag to enable manual private link creation instead of automatic. 
    Allows for custom VPC PrivateLink configuration.
    EOF
  type        = bool
  default     = false
}

variable "booter" {
  description = <<EOF
    Booter configuration for advanced container bootstrapping (optional). 
    Used for custom container initialization and configuration.
    EOF
  type = object({
    account_id = optional(string, "")
    region     = optional(string, "")
    prefix     = optional(string, "")
    image      = optional(string, "")
  })
  default = {
    account_id = ""
    region     = ""
    prefix     = ""
    image      = ""
  }
}