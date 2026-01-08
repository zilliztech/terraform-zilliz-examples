# EKS Cluster Access and Management Guide

This guide explains how customers can access and manage the EKS cluster created by the BYOC-I deployment.

## Important: Private Endpoint Configuration

**By default, BYOC-I deployments create EKS clusters with private endpoint access only** for security reasons. This means:

- The Kubernetes API server endpoint is **only accessible from within the VPC**
- Public internet access to the API server is **disabled by default**
- You **must establish network connectivity** to the VPC before you can access the cluster

> **Note**: You can also configure the cluster to use both public and private endpoint access modes, which allows access over the public internet. For details, see [Public and Private Endpoint Access](#public-and-private-endpoint-access).

For more information about EKS endpoint access modes, see the [AWS EKS Cluster Endpoint Documentation](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html).

### Private Endpoint Network Connectivity Requirements

Before accessing the EKS cluster with private endpoint access, you must ensure network connectivity to the VPC. Common options include:

1. **AWS CloudShell**: Use AWS CloudShell from the AWS Console (requires VPC Peering or VPN connection to the EKS VPC)
2. **VPN Connection**: Connect your local network to the VPC via VPN
3. **AWS Direct Connect**: Use AWS Direct Connect for dedicated network connection
4. **Bastion Host**: Launch an EC2 instance in a public subnet and SSH into it
5. **AWS Systems Manager Session Manager**: Use SSM to connect to an EC2 instance in the VPC
6. **AWS Cloud9 IDE**: Create a Cloud9 environment within the VPC
7. **VPC Peering**: Establish VPC peering connection between your VPC and the EKS VPC
8. **Transit Gateway**: Connect networks via AWS Transit Gateway

**Note**: The cluster's control plane security group must allow ingress traffic on port 443 from your source network. For more details, see [Accessing a private only API server](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#private-access).

## Prerequisites

Before accessing the EKS cluster, ensure you have:

1. **Network Connectivity**: Established connection to the VPC (see above)
2. **AWS CLI** installed and configured with appropriate credentials
3. **kubectl** installed (version compatible with your EKS cluster version)
4. **AWS Credentials**: Use AWS credentials from the IAM role that was used to create the EKS cluster (recommended). This role automatically has cluster-admin permissions configured.

   > **Note**: If you need to use a different IAM role or user, see [Granting Access to Other IAM Roles or Users](#granting-access-to-other-iam-roles-or-users) section below.

## Configuring kubectl Access

The simplest way to configure kubectl is using the AWS CLI `update-kubeconfig` command. This command automatically retrieves cluster information (endpoint, certificate authority, etc.) from AWS and configures authentication.

**Recommended**: Use AWS credentials from the IAM role that was used to create the EKS cluster (the same role used during Terraform deployment). This role automatically has cluster-admin permissions configured, so no additional setup is needed.

```bash
# Set your AWS region and cluster name
export AWS_REGION=<your-region>  # e.g., us-east-1
export CLUSTER_NAME=<your-cluster-name>

# Update kubeconfig (must be run from a location with VPC network access)
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
```

This command:
- Retrieves cluster information (endpoint, certificate authority, etc.) from AWS
- Configures authentication using your current AWS credentials via EKS access entries
- Adds the cluster to your `~/.kube/config` file
- Sets the current context to the new cluster

**Prerequisites**:
1. **Network Connectivity**: This command must be run from a location that has network connectivity to the VPC (since the endpoint is private by default)
2. **IAM Role**: Ensure you're using AWS credentials from the role that created the cluster (or see [Granting Access to Other IAM Roles or Users](#granting-access-to-other-iam-roles-or-users) if using a different role)

For more details, see [Connect kubectl to an EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html).

## Granting Access to Other IAM Roles or Users

BYOC-I EKS clusters use **EKS Access Entries** for authentication. If you need to grant access to IAM roles or users other than the one that created the cluster, you must create an access entry for them first.

For more information about EKS Access Entries, see the [AWS EKS Access Entries Documentation](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html).

If you need to grant access to other IAM roles or users, you must create an access entry for them first. Follow these steps:

1. **Create an access entry** for the IAM principal:
   ```bash
   aws eks create-access-entry \
     --cluster-name $CLUSTER_NAME \
     --principal-arn arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME \
     --region $AWS_REGION
   ```

2. **Associate an access policy** with the access entry:
   ```bash
   aws eks associate-access-policy \
     --cluster-name $CLUSTER_NAME \
     --principal-arn arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME \
     --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
     --access-scope type=cluster \
     --region $AWS_REGION
   ```

Available access policies:
- `AmazonEKSClusterAdminPolicy`: Full cluster administrator access
- `AmazonEKSAdminPolicy`: Administrative access (can manage most resources)
- `AmazonEKSViewPolicy`: Read-only access

For more details, see:
- [Create access entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html#creating-access-entries)
- [Associate access policies](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html#associating-access-policies)
- [Review access policy permissions](https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html)

## Public and Private Endpoint Access

You can configure the cluster to use both public and private endpoint access modes. This allows you to access the cluster from the internet while maintaining private access within the VPC.

**Important**: When enabling public access, you must configure CIDR whitelist with precise network ranges to restrict access to specific IP addresses or networks.

```bash
# Enable public access with CIDR whitelist
# Replace <YOUR_IP_CIDR> with your IP address or CIDR block (e.g., 203.0.113.0/24)
aws eks update-cluster-config \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --resources-vpc-config endpointPublicAccess=true,endpointPrivateAccess=true,publicAccessCidrs=["<YOUR_IP_CIDR>"]

# Example with multiple CIDR blocks:
# aws eks update-cluster-config \
#   --name $CLUSTER_NAME \
#   --region $AWS_REGION \
#   --resources-vpc-config endpointPublicAccess=true,endpointPrivateAccess=true,publicAccessCidrs=["203.0.113.0/24","198.51.100.0/24"]

# Disable public access if no longer needed
aws eks update-cluster-config \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --resources-vpc-config endpointPublicAccess=false,endpointPrivateAccess=true
```

For more details about configuring endpoint access and CIDR whitelist, see [Configure network access to cluster API server endpoint](https://docs.aws.amazon.com/eks/latest/userguide/config-cluster-endpoint.html).

## Deploying Kubernetes Resources

After configuring kubectl access, you can deploy Kubernetes resources to the cluster. There are two main approaches:

### Method 1: Using kubectl (Recommended for Manual Operations)

Once kubectl is configured and you have network connectivity to the VPC:

```bash
# Verify access
kubectl cluster-info
kubectl get nodes

# Deploy resources using kubectl
kubectl apply -f your-manifest.yaml

# Or create resources directly
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

**Note**: All `kubectl` commands must be executed from a location with network connectivity to the VPC, as the API server endpoint is private.

### Method 2: Using Terraform Kubernetes Provider

You can also deploy Kubernetes resources directly using Terraform, which is useful for infrastructure-as-code workflows. The Terraform Kubernetes provider can authenticate using the EKS cluster's access entry system.

#### Step 1: Configure Terraform Kubernetes Provider

Add the Kubernetes provider to your Terraform configuration:

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Data source to get EKS cluster information
data "aws_eks_cluster" "example" {
  name = var.cluster_name  # Use your cluster name (dataplane_id or custom name)
}

data "aws_eks_cluster_auth" "example" {
  name = data.aws_eks_cluster.example.name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.example.token
}
```

#### Step 2: Deploy Kubernetes Resources

Now you can create Kubernetes resources using Terraform:

```hcl
# Example: Create a namespace
resource "kubernetes_namespace" "example" {
  metadata {
    name = "example-namespace"
  }
}

# Example: Create a ConfigMap
resource "kubernetes_config_map" "example" {
  metadata {
    name      = "example-config"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  data = {
    config_key = "config_value"
  }
}

# Example: Create a Deployment
resource "kubernetes_deployment" "example" {
  metadata {
    name      = "example-deployment"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "example"
      }
    }

    template {
      metadata {
        labels = {
          app = "example"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Example: Create a Service
resource "kubernetes_service" "example" {
  metadata {
    name      = "example-service"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.example.spec[0].selector[0].match_labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
```

#### Step 3: Apply Terraform Configuration

```bash
# Initialize Terraform (if not already done)
terraform init

# Plan the changes
terraform plan

# Apply the configuration
terraform apply
```

**Important Notes**:
- The Terraform Kubernetes provider uses the AWS credentials configured in your environment
- The IAM identity used must have an access entry configured for the EKS cluster (the role used to create the cluster works by default)
- Terraform must be run from a location with network connectivity to the VPC (or use a CI/CD system within the VPC)
- The `data.aws_eks_cluster_auth` data source automatically retrieves the authentication token using your AWS credentials

## Troubleshooting

### Cannot Connect to Cluster

**Error**: `Unable to connect to the server: dial tcp: lookup <endpoint>`

**Solutions**:
1. Verify your AWS credentials are configured: `aws sts get-caller-identity`
2. Check if cluster endpoint is accessible (for private clusters, ensure you're in the VPC)
3. Verify cluster name is correct: `aws eks list-clusters --region $AWS_REGION`
4. Re-run `aws eks update-kubeconfig` command

### Authentication Errors

**Error**: `error: You must be logged in to the server (Unauthorized)`

**Solutions**:
1. Verify your IAM user/role has EKS access permissions
2. Check if your AWS credentials are expired: `aws sts get-caller-identity`
3. Ensure you're using the correct AWS profile: `export AWS_PROFILE=<profile-name>`
4. Verify cluster access entry exists (for EKS 1.23+)

### Private Cluster Access

**Issue**: Cannot access private EKS cluster from local machine

**Solutions**:
1. **Establish VPC Network Connectivity**: Ensure you have network connectivity to the VPC (see [Private Endpoint Network Connectivity Requirements](#private-endpoint-network-connectivity-requirements) above)

2. **Verify Security Group Rules**: Ensure the EKS control plane security group allows ingress on port 443 from your source network

3. **Verify DNS Configuration**: For private endpoints, ensure your VPC has:
   - `enableDnsHostnames = true`
   - `enableDnsSupport = true`
   - DHCP options set includes `AmazonProvidedDNS`

4. **Verify Access Entry**: Ensure your IAM identity has an access entry configured:
   ```bash
   # List access entries
   aws eks list-access-entries --cluster-name $CLUSTER_NAME --region $AWS_REGION
   
   # Describe your access entry
   aws eks describe-access-entry \
     --cluster-name $CLUSTER_NAME \
     --principal-arn $(aws sts get-caller-identity --query Arn --output text) \
     --region $AWS_REGION
   ```

## Security Best Practices

1. **Use Private Endpoints**: For production, disable public endpoint access (default for BYOC-I)
2. **IAM Authentication**: Always use IAM for cluster authentication via EKS Access Entries
3. **Least Privilege**: Grant only necessary permissions to users/roles when creating access entries
4. **Audit Logging**: Enable EKS control plane logging for audit purposes

## Additional Resources

### AWS Documentation
- [AWS EKS Cluster Endpoint Documentation](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html) - Detailed information about endpoint access modes
- [Configure network access to cluster API server endpoint](https://docs.aws.amazon.com/eks/latest/userguide/config-cluster-endpoint.html) - How to configure endpoint access and CIDR whitelist
- [AWS EKS Access Entries Documentation](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html) - Managing IAM access to Kubernetes clusters
- [Connect kubectl to EKS Cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html) - Configuring kubectl for EKS
- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/) - Complete EKS documentation
- [Accessing a Private Only API Server](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#private-access) - Network connectivity options

### Kubernetes Documentation
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) - Quick reference for kubectl commands
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Official Kubernetes documentation

### Best Practices
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/) - AWS EKS best practices guide

### Zilliz Documentation
- [Zilliz Cloud Documentation](https://docs.zilliz.com/) - Zilliz Cloud platform documentation

## Getting Help

If you encounter issues:

1. Check Terraform outputs: `terraform output`
2. Review AWS CloudWatch logs for EKS
3. Check node group status in AWS Console
4. Verify IAM permissions and roles
5. Contact Zilliz Cloud support with cluster details

