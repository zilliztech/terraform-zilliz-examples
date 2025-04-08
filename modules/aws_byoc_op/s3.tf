module "s3_bucket" {
  count = local.create_bucket? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket   = "${local.dataplane_id}-milvus"
  acl      = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}