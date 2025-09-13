#
# Terraform Variables Template for AWS Zilliz BYOC Project
#
# This is a sample terraform variables file that demonstrates how to configure
# your AWS BYOC (Bring Your Own Cloud) deployment with Zilliz Cloud.
#
# Instructions:
# 1. Copy this file and rename it to 'terraform.tfvars'
# 2. Replace all placeholder values (vpc-xxxxxxxxxxxxxxxxx, subnet-xxxxxxxxxxxxxxxxx, etc.) 
#    with your actual AWS resource IDs
# 3. Customize the optional parameters according to your requirements
# 4. Run 'terraform plan' to verify your configuration before applying
#
# Required Prerequisites:
# - AWS credentials configured (AWS CLI profile or access keys)
# - Terraform installed
# - Zilliz Cloud API key configured in provider.tf
# - Existing VPC, subnets, and security group in your AWS account
#
# For detailed setup instructions, refer to the README.md file
#

# The ID of the existing customer VPC, otherwise it will create a new VPC if not provided
customer_vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# The IDs of the private subnets for the customer VPC, prerequsite: customer_vpc_id should be provided
customer_private_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx"]

# The IDs of the private subnets for the customer's EKS control plane
# Must be in at least two different availability zones
# Defaults to customer_private_subnet_ids if not provided
customer_eks_control_plane_private_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]

# The ID of the security group for the customer VPC, prerequsite: customer_vpc_id should be provided
customer_security_group_id = "sg-xxxxxxxxxxxxxxxxx"

# The IDs of the security group for the cluster, prerequsite: customer_vpc_id should be provided
customer_cluster_additional_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]

# The IDs of the security group for the node group, prerequsite: customer_vpc_id should be provided
customer_node_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]

# The IDs of the security group for the private link, prerequsite: customer_vpc_id should be provided
customer_private_link_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]

# The name of the customer bucket
# If empty, uses "${dataplane_id}-milvus" as bucket name
customer_bucket_name = "your-bucket-name"

# The name of the customer EKS cluster
# If empty, uses "${dataplane_id}" as EKS cluster name
customer_eks_cluster_name = "your-eks-cluster-name"

# The name of the customer storage role for S3 access
# If empty, uses "${dataplane_id}-storage-role" as role name
customer_storage_role_name = "your-storage-role-name"

# The name of the customer EKS addon role for S3 access
# If empty, uses "${dataplane_id}-addon-role" as role name
customer_eks_addon_role_name = "your-eks-addon-role-name"

# The name of the customer EKS cluster role
# If empty, uses "${dataplane_id}-eks-role" as role name
customer_eks_role_name = "your-eks-role-name"

# The name of the customer maintenance role for cluster administration
# If empty, uses "${dataplane_id}-maintenance-role" as role name
customer_maintenance_role_name = "your-maintenance-role-name"

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