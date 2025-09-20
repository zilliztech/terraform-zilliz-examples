resource "random_id" "short_uuid" {
  byte_length = 3  # 3 bytes = 6 characters when base64 encoded
}
locals {
  # Boolean flag to determine if customer is providing their own existing VPC infrastructure
  # Returns true if customer_vpc_id variable is not empty, false otherwise
  is_existing_vpc = var.customer_vpc_id != ""
  
  # Truncated project identifier for resource naming, limited to first 10 characters
  # Extracted from the Zilliz cloud BYOC project settings to ensure uniqueness
  short_project_id = substr(data.zillizcloud_byoc_i_project_settings.this.id, 0, 10)
  
  # Standardized naming prefix for all AWS resources created by this Terraform configuration
  # Combines "zilliz" brand, short project ID, and random hex for global uniqueness
  prefix_name = "zilliz-${local.short_project_id}-${random_id.short_uuid.hex}"
  
  # Data plane identifier from Zilliz cloud configuration
  # Used to associate AWS resources with the correct Zilliz data plane instance
  dataplane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id
  
  # VPC ID selection based on customer preference
  # Uses customer-provided VPC if available, otherwise uses newly created VPC from vpc module
  vpc_id = local.is_existing_vpc ? var.customer_vpc_id :module.vpc[0].vpc_id
  
  # Private link security group IDs selection based on customer preference
  # Uses customer-provided security groups if available, otherwise uses VPC module's default security group
  # When using existing VPC: customer MUST provide private_link_security_group_ids (enforced by validation in variables.tf)
  # CRITICAL: These security groups must allow agent pods to access the private link endpoint
  # to ensure successful BYOC connection from customer's data plane to Zilliz cloud control plane
  private_link_security_group_ids = length(var.customer_private_link_security_group_ids) > 0 ? var.customer_private_link_security_group_ids : [module.vpc[0].security_group_id]

  # Node security group IDs selection based on customer preference
  node_security_group_ids = var.customer_node_security_group_ids
  
  # Private subnet IDs for EKS worker nodes and database components
  # Selects between customer-provided subnets or newly created private subnets
  subnet_ids =  local.is_existing_vpc ? var.customer_private_subnet_ids : module.vpc[0].private_subnets
  
  # Additional subnet IDs specifically for Kubernetes pod networking (optional)
  # Only used when customer provides existing VPC with dedicated pod subnets
  customer_pod_subnet_ids = local.is_existing_vpc ? var.customer_pod_subnet_ids : []
  
  # Subnet IDs for EKS control plane ENIs (Elastic Network Interfaces)
  # Controls which subnets the EKS API server endpoint can be accessed from
  eks_control_plane_subnet_ids = local.is_existing_vpc ? var.customer_eks_control_plane_private_subnet_ids : module.vpc[0].private_subnets
  
  # AWS region extracted from Zilliz cloud settings, removing "aws-" prefix
  # Normalizes region format from Zilliz naming convention to standard AWS region names
  region = replace(data.zillizcloud_byoc_i_project_settings.this.region, "aws-", "")
  
  # Flag indicating whether VPC private link should be enabled for secure connectivity
  # Determined by Zilliz cloud project configuration for enhanced network security
  enable_private_link =  data.zillizcloud_byoc_i_project_settings.this.private_link_enabled
  
  # External ID for cross-account IAM role assumption security
  # Used by Zilliz cloud services to securely access customer AWS resources
  external_id = data.zillizcloud_external_id.current.id
  
  # Configuration object for Zilliz monitoring and management agent
  # Contains authentication token and container image URL for agent deployment
  agent_config = {
    auth_token = data.zillizcloud_byoc_i_project_settings.this.op_config.token
    tag        = data.zillizcloud_byoc_i_project_settings.this.op_config.agent_image_url
  }

  # Kubernetes node group specifications and resource quotas
  # Defines the compute capacity and node types for the EKS cluster
  k8s_node_groups = data.zillizcloud_byoc_i_project_settings.this.node_quotas
  
  # Zilliz project identifier for resource tagging and organization
  # Links AWS resources back to the specific Zilliz cloud project
  project_id = data.zillizcloud_byoc_i_project_settings.this.project_id
  
  # Data plane identifier (duplicate of dataplane_id above)
  # Used for consistency across different resource configurations
  data_plane_id = data.zillizcloud_byoc_i_project_settings.this.data_plane_id
  
  # S3 bucket identifier created by the s3 module
  # Used for storing Zilliz data, backups, and operational logs
  s3_bucket_id = module.s3.s3_bucket_id
  
  # IAM role ARN for EKS cluster service account
  # Provides necessary permissions for EKS cluster operations and AWS service integration
  eks_role = module.eks.eks_role
  
  # IAM role ARN for cluster maintenance operations
  # Used for automated patching, updates, and maintenance tasks
  maintenance_role = module.eks.maintenance_role
  
  # IAM role ARN for EKS add-ons (AWS Load Balancer Controller, EBS CSI driver, etc.)
  # Enables EKS add-ons to interact with AWS services on behalf of the cluster
  eks_addon_role = module.eks.eks_addon_role
  
  # IAM role ARN for persistent storage operations
  # Allows EKS to manage EBS volumes and other storage resources for stateful workloads
  storage_role = module.eks.storage_role
  
  # VPC endpoint ID for private link connectivity (conditional)
  # Only populated when private link is enabled, provides secure communication path
  byoc_endpoint = local.enable_private_link ? module.private_link[0].endpoint_id : null
  
  # Flag to enable/disable endpoint creation based on user configuration
  # Controls whether additional network endpoints should be provisioned
  enable_endpoint = var.enable_endpoint

  # External configuration object passed to Zilliz cloud services
  # Contains EKS cluster details and customer ECR registry information for container management
  ext_config = {
    eks_cluster_name = module.eks.eks_cluster_name
    ecr = var.customer_ecr
  }
}