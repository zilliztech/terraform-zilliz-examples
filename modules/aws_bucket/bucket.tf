data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  for_each = var.s3_bucket_names
  bucket   = "${var.name}-${each.key}"
  acl      = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}

output "s3_bucket_ids" {
  value = module.s3_bucket["milvus"].s3_bucket_id
}
