module "aws_bucket" {
  source = "../../modules/aws_bucket"

  region      = var.region
  name            = var.name
  s3_bucket_names = ["milvus"]
}

data "zillizcloud_external_id" "current" {}

module "aws_iam" {
  source = "../../modules/aws_iam"

  bucketName = module.aws_bucket.s3_bucket_ids
  name       = var.name
  ExternalId = data.zillizcloud_external_id.current.id

}

module "aws_vpc" {
  source = "../../modules/aws_vpc"

  region          = var.region
  vpc_cidr            = var.vpc_cidr
  name                = var.name
  enable_private_link = var.enable_private_link
}


resource "zillizcloud_byoc_project" "this" {
  name = var.name
  status = "RUNNING"



  aws = {
    region = "aws-${var.region}"

    network = {
      vpc_id             = module.aws_vpc.vpc_id
      subnet_ids         = module.aws_vpc.subnet_ids
      security_group_ids = [module.aws_vpc.sg_id]
      vpc_endpoint_id    = var.enable_private_link ? module.aws_vpc.vpc_endpoint : null
    }
    role_arn = {
      storage       = module.aws_iam.storage_role_arn
      eks           = module.aws_iam.eks_role_arn
      cross_account = module.aws_iam.cross_account_role_arn
    }
    storage = {
      bucket_id = module.aws_bucket.s3_bucket_ids
    }

   
  }

   instances = {
    core = {
      vm = var.instances.core.vm
      count = var.instances.core.count
    }
    fundamental = {
      vm = var.instances.fundamental.vm
      min_count = var.instances.fundamental.min_count
      max_count = var.instances.fundamental.max_count
    }
    search = {
      vm = var.instances.search.vm
      min_count = var.instances.search.min_count
      max_count = var.instances.search.max_count
    }
    index = {
      vm = var.instances.index.vm
      min_count = var.instances.index.min_count
      max_count = var.instances.index.max_count
    }
    auto_scaling = var.instances.auto_scaling
    arch = var.instances.arch
   }

  depends_on = [module.aws_vpc, module.aws_bucket, module.aws_iam]
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

output "project_id" {
  value = zillizcloud_byoc_project.this.id
}
