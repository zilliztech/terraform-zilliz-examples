# Quick Start Guide for Zilliz BYOC

This guide will walk you through downloading Terraform CLI, setting up the environment, and applying Terraform configuration for creating all the dependencies required by Zilliz BYOC.

## 1. Install Terraform CLI

Before you start, you need to install Terraform CLI on your system. Follow the official installation guide for your operating system:
[Terraform CLI Installation Guide](https://developer.hashicorp.com/terraform/downloads)

[Configuring Authentication (Using AWS as an Example)](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build)


## 2. Quick Start

##### 2.1 Clone the Project Repository
First, clone the project repository to your local environment:
```
git clone https://github.com/zilliztech/zilliz-byoc-prepare.git
cd zilliz-byoc-prepare/byoc-prepare
```

##### 2.2 Configure terraform.tfvars.json
Edit the terraform.tfvars.json file to specify the required variables. Below is an explanation of the variables you need to configure:

`aws_region`: AWS region where resources will be deployed (e.g., us-west-2).
`vpc_cidr`: CIDR block for the VPC (e.g., 10.0.0.0/16).
`name`: A unique name for the BYOC project.
`ExternalId`: The external ID provided by the Zilliz console.

An example of terraform.tfvars.json:
```
{
  "aws_region": "us-west-2",
  "vpc_cidr": "10.0.0.0/16",
  "name": "my-byoc-project",
  "ExternalId": "example-external-id"
}
```
##### 2.3 Initialize and Apply Terraform Configuration
Run the following commands to initialize the Terraform environment and apply the configuration:

Initialize Terraform:

`terraform init`

Verify those resources will be created by Terraform:

`terraform plan`

Apply the Configuration:

`terraform apply`

Review the plan when prompted and type yes to confirm and proceed with the resource creation.

##### 3. Verify Deployment

After the terraform apply command completes, verify that all resources have been successfully created. You can check the AWS Management Console or use the Terraform state output for confirmation.

An example of output:

```
bucket_name = "byoc-name-milvus"
cross_account_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/zilliz-byoc-byoc-name-cross-account-role"
eks_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/zilliz-byoc-byoc-name-eks-role"
external_id = "externalId from zilliz"
security_group_id = "sg-xxxxxxxxxxxx"
storage_role_arn = "arn:aws:iam::xxxxxxxxxxxx:role/zilliz-byoc-byoc-name-storage-role"
subnet_id = [
  "subnet-xxxxxxxxxxxx",
  "subnet-xxxxxxxxxxxx",
  "subnet-xxxxxxxxxxxx",
]
vpc_id = "vpc-xxxxxxxxxxxx"
```

## Tips for Beginners Using Terraform
When working with Terraform, it’s essential to understand how state files (`terraform.tfstate`) work:

#### [Terraform State Tracks Resources](https://developer.hashicorp.com/terraform/language/state):

Terraform maintains a state file (`terraform.tfstate`) to keep track of the infrastructure it manages. This file is critical for Terraform to know what resources exist and their current configurations.