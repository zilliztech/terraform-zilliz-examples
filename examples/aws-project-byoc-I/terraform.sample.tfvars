#
# Terraform Variables Template for AWS Zilliz BYOC Project
#
# This is a sample terraform variables file that demonstrates how to configure
# your AWS BYOC (Bring Your Own Cloud) deployment with Zilliz Cloud.
#
# Instructions:
# 1. Copy this file and rename it to 'terraform.tfvars'
# 2. Choose VPC configuration: leave customer_vpc_id empty for new VPC or provide existing VPC details
# 3. Customize the optional parameters according to your requirements
#
# Required Prerequisites:
# - AWS credentials configured (AWS CLI profile or access keys)
# - Terraform installed
# - Zilliz Cloud API key configured in provider.tf
# - (Optional) Existing VPC, subnets, and security group if using customer-managed VPC
#
# For detailed setup instructions, refer to the README.md file
#


customer_private_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx"]

# The IDs of the pod subnets for the customer VPC
customer_pod_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx"]

# ============================================================================
# VPC CONFIGURATION - Choose between new VPC creation or existing VPC usage
# ============================================================================

# The ID of an existing customer VPC (optional)
# Leave empty ("") to create a new VPC, or provide existing VPC ID
customer_vpc_id = ""

# CIDR block for new VPC creation (only used when customer_vpc_id is empty)
vpc_cidr = "10.0.0.0/16"

# The IDs of private subnets in the customer VPC (required when using existing VPC)
# Leave empty when creating new VPC
customer_private_subnet_ids = []

# The ID of the security group for the customer VPC (required when using existing VPC)
# Leave empty when creating new VPC
customer_security_group_id = ""

# The IDs of pod subnets for Kubernetes networking (optional, for existing VPC only)
customer_pod_subnet_ids = []

# The IDs of private subnets for EKS control plane (optional)
# Must be in at least two different availability zones when provided
# Defaults to customer_private_subnet_ids if not provided
customer_eks_control_plane_private_subnet_ids = []


# ============================================================================
# CUSTOM RESOURCE NAMING - All optional, leave empty to use defaults
# ============================================================================

# The name of the customer bucket
# If empty, uses "${local.prefix_name}-bucket" as bucket name
customer_bucket_name = ""

# The name of the customer EKS cluster
# If empty, uses "${local.prefix_name}" as EKS cluster name
customer_eks_cluster_name = ""

# The name of the customer storage role for S3 access
# If empty, uses "${local.prefix_name}-storage-role" as role name
customer_storage_role_name = ""

# The name of the customer EKS addon role for S3 access
# If empty, uses "${local.prefix_name}-addon-role" as role name
customer_eks_addon_role_name = ""

# The name of the customer EKS cluster role
# If empty, uses "${local.prefix_name}-eks-role" as role name
customer_eks_role_name = ""

# The name of the customer maintenance role for cluster administration
# If empty, uses "${local.prefix_name}-maintenance-role" as role name
customer_maintenance_role_name = ""

# ============================================================================
# ADDITIONAL CONFIGURATION
# ============================================================================

# Customer ECR configuration containing account ID, region, and prefix
customer_ecr = {
  ecr_account_id = "965570967084"
  ecr_region     = "us-west-2"
  ecr_prefix     = "zilliz-byoc"
}

# Custom tags to apply to resources (EKS cluster, bucket, IAM roles, VPC PrivateLink endpoint)
custom_tags = {
  custom_key   = "custom_value"
  custom_key_2 = "custom_value_2"
}

# Enable endpoint creation
enable_endpoint = false

# Enable manual private link creation
enable_manual_private_link = false

# Booter configuration for advanced container bootstrapping (optional)
booter = {
  account_id = ""
  region     = ""
  prefix     = ""
  image      = ""
}