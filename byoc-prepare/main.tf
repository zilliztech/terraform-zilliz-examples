module "aws_bucket" {
  source = "../modules/aws_bucket"

  aws_region      = var.aws_region
  name            = var.name
  s3_bucket_names = ["milvus"]
}

module "aws_iam" {
  source = "../modules/aws_iam"

  bucketName = module.aws_bucket.s3_bucket_ids
  name       = var.name
  ExternalId = var.ExternalId

}

module "aws_vpc" {
  source = "../modules/aws_vpc"

  aws_region = var.aws_region
  vpc_cidr   = var.vpc_cidr
  name       = var.name

}

output "vpc_id" {
  value = module.aws_vpc.vpc_id
}

output "subnet_id" {
  value = module.aws_vpc.subnet_ids
}

output "security_group_id" {
  value = module.aws_vpc.sg_id
}

output "bucket_name" {
  value = module.aws_bucket.s3_bucket_ids
}

output "cross_account_role_arn" {
  value = module.aws_iam.cross_account_role_arn
}

output "eks_role_arn" {
  value = module.aws_iam.eks_role_arn
}

output "storage_role_arn" {
  value = module.aws_iam.storage_role_arn
}

output "external_id" {
  value = module.aws_iam.external_id
  
}