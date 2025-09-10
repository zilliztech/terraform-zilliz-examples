# Provisioning AWS Zilliz BYOC project with customer managed VPC
This example is using following modules and [zilliz-cloud provider](https://registry.terraform.io/providers/zilliztech/zillizcloud/latest):
- [aws_byoc_i/eks module](../../modules/aws_byoc_i/eks)
- [aws_byoc_i/privatelink module](../../modules/aws_byoc_i/privatelink)
- [aws_byoc_i/s3 module](../../modules/aws_byoc_i/s3)

This example provides an example deployment of: zilliz cloud BYOC project with customer managed VPC(including VPC, Security Group, Subnets),
enabling customization of the bucket name, EKS cluster name, and four IAM role names (EKS Cluster Role, EKS Add-on Role, Cluster Maintenance Role, and Storage Role),
supporting integration with the customer's existing ECR,
and allowing the attachment of custom tags to the EKS cluster, bucket, IAM roles, and VPC PrivateLink endpoint.

## Prerequisites
Ensure that you are the owner of a BYOC-I organization.

## Procedures

### Step 1: Prepare the deployment environment
A deployment environment is a local machine, a virtual machine (VM), or a CI/CD pipeline configured to run the Terraform configuration files and deploy the data plane of your BYOC-I project. In this step, you need to

1. Configure AWS credentials (AWS profile or access key).
   For details on how to configure AWS credentials, refer to this [document](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

2. Install the latest Terraform binary.
   For details on how to install Terraform, refer to this [document](https://developer.hashicorp.com/terraform/install?product_intent=terraform).

3. Configure authentication to zillizcloud providers.
   In the Zilliz Cloud console, go to your organization's API Keys page and copy your API key. 
   Then, open the `providers.tf` file and set up authentication for the `zillizcloud` providers using that API key.
    ```
    provider "zillizcloud" {
      api_key      = "xxxxxxxxxxxxxxx"
    }
    ```
### Step 2: Configure input values to your terraform template
Navigate to `variables.tf` and configure input values to your terraform template.

| Name                                            | Description                                                  | Type           | Default                                                      | Required |
| ----------------------------------------------- | ------------------------------------------------------------ | -------------- | ------------------------------------------------------------ | -------- |
| `project_id`                                    | The ID of the Zilliz BYOC project                           | `string`       | —                                                            | Yes      |
| `dataplane_id`                                  | The ID of the Zilliz data plane                             | `string`       | —                                                            | Yes      |
| `customer_vpc_id`                               | The ID of an existing customer VPC (leave empty to create new VPC) | `string`       | `""`                                                         | No       |
| `vpc_cidr`                                      | CIDR block for new VPC creation (only used when customer_vpc_id is empty) | `string`       | `"10.0.0.0/16"`                                              | No       |
| `customer_security_group_id`                    | The ID of the security group for the customer VPC (required when using existing VPC) | `string`       | `""`                                                         | No       |
| `customer_private_subnet_ids`                   | The IDs of private subnets in the customer VPC (required when using existing VPC) | `list(string)` | `[]`                                                         | No       |
| `customer_pod_subnet_ids`                       | Additional subnet IDs for Kubernetes pod networking (optional, for existing VPC only) | `list(string)` | `[]`                                                         | No       |
| `customer_eks_control_plane_private_subnet_ids` | The IDs of private subnets for EKS control plane, must be in at least two different availability zones. Defaults to `customer_private_subnet_ids` if not provided | `list(string)` | `[]`                                                         | No       |
| `customer_ecr`                                  | Customer ECR configuration containing account ID, region, and prefix | `object`       | `{ecr_account_id = "965570967084", ecr_region = "us-west-2", ecr_prefix = "zilliz-byoc"}` | No       |
| `customer_bucket_name`                          | The name of the customer bucket. If empty, use "${dataplane_id}-milvus" as bucket name. | `string`       | `""`                                                         | No       |
| `customer_eks_cluster_name`                     | The name of the customer EKS cluster. If empty, use "${dataplane_id}" as EKS cluster name. | `string`       | `""`                                                         | No       |
| `customer_storage_role_name`                    | The name of the customer storage role for S3 access. If empty, use "${dataplane_id}-storage-role" as role name. | `string`       | `""`                                                         | No       |
| `customer_eks_addon_role_name`                  | The name of the customer EKS addon role for S3 access. If empty, use "${dataplane_id}-addon-role" as role name. | `string`       | `""`                                                         | No       |
| `customer_eks_role_name`                        | The name of the customer EKS cluster role. If empty, use "${dataplane_id}-eks-role" as role name. | `string`       | `""`                                                         | No       |
| `customer_maintenance_role_name`                | The name of the customer maintenance role for cluster administration. If empty, use "${dataplane_id}-maintenance-role" as role name. | `string`       | `""`                                                         | No       |
| `custom_tags`                                   | Custom tags to apply to resources                            | `map(string)`  | `{}`                                                         | No       |

### Step 3: Deploy to your AWS environment
Run the following commands to initialize the Terraform environment and apply the configuration:

Initialize Terraform: `terraform init`

Verify those resources will be created by Terraform: `terraform plan`

Apply the Configuration: `terraform apply`

Review the plan when prompted and type yes to confirm and proceed with the resource creation.

### Step 4: Verify Deployment
After the terraform apply command completes, verify that all resources have been successfully created. You can check the AWS Management Console or use the Terraform state output for confirmation.

Output:

| Name                                      | Description                |
|-------------------------------------------|----------------------------|
| `data_plane_id`                              | BYOC project data plane ID |
| `project_id`                              | BYOC project ID            |


> **Note:**  
> When creating EKS clusters and node groups, you must ensure that the required AWS service-linked roles are already created in your AWS account.  
> 
> Specifically, the following service roles are needed:
> - `AWSServiceRoleForAmazonEKS` (`eks.amazonaws.com`)
> - `AWSServiceRoleForAmazonEKSNodegroup` (`eks-nodegroup.amazonaws.com`)
>
> These roles are typically created automatically by AWS when you first create an EKS cluster or node group via the AWS Console. However, when using Terraform or other automation, you may need to create them manually if they do not exist.
>
> You can create these roles using the AWS CLI:
> ```sh
> aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
> aws iam create-service-linked-role --aws-service-name eks-nodegroup.amazonaws.com
> ```
>
> For more details, see the [AWS documentation on service-linked roles for EKS](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html).
