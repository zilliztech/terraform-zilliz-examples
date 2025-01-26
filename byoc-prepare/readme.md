
# 1. terraform init to download the provider(zillizcloud and aws)
terraform init

# 2. config provider.tf
- set the api_key
- set the byoc_mode to true if you are using byoc mode
- set the environment variable for uat env
export ZILLIZCLOUD_HOST_ADDRESS=https://api.cloud-uat3.zilliz.com


# 3. config terraform.tfvars.json
- set the aws_region
- set the vpc_cidr
- set the name
- set the ExternalId

# 4. terraform plan to check the changes
terraform plan

# 5. terraform apply to apply the changes
terraform apply


(optional)update oidc and federated principal for idempotence
```
module "aws_iam" {
  source = "../modules/aws_iam"

  bucketName = module.aws_bucket.s3_bucket_ids
  name       = var.name
  ExternalId = var.ExternalId

  zillizAccount = "306787409409"

  + eks_oidc_url = "oidc.eks.us-west-2.amazonaws.com/id/CDA9209BE615B2A940DC9745EDE5A612"
  + federated_principal = "arn:aws:iam::041623484421:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/CDA9209BE615B2A940DC9745EDE5A612"
}
```

# 6. clean up
terraform destroy