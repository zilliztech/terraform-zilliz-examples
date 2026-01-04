data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  for_each = var.s3_bucket_names
  bucket   = "${var.name}-${each.key}"
  acl      = "private"

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  tags = {
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}

output "s3_bucket_ids" {
  value = module.s3_bucket["milvus"].s3_bucket_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable_s3_kms ? 1 : 0
  bucket = module.s3_bucket["milvus"].s3_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.s3_kms_key_arn
    }

    bucket_key_enabled = true
  }
}
