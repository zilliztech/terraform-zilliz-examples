# 1. set the environment variable for uat env
export ZILLIZCLOUD_HOST_ADDRESS=https://api.cloud-uat3.zilliz.com

# 2. terraform init to download the provider(zillizcloud and aws)
terraform init

# 3. terraform plan to check the changes
terraform plan

# 4. terraform apply to apply the changes
terraform apply


## update oidc and federated principal(optional)
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

# 5. clean up
terraform destroy