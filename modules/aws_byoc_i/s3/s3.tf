data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket   = local.bucket_name
  acl      = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = merge({
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
}