data "aws_caller_identity" "current" {}

locals {
  create_key  = var.aws_cse_exiting_key_arn == ""
  cse_key_arn = local.create_key ? aws_kms_key.zilliz_cse[0].arn : var.aws_cse_exiting_key_arn
}

# Multi-Region symmetric KMS key for Zilliz cluster encryption and decryption
resource "aws_kms_key" "zilliz_cse" {
  count = local.create_key ? 1 : 0

  description              = "Multi-Region symmetric KMS key for Zilliz cluster encryption and decryption"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region             = true
  enable_key_rotation      = true

  tags = {
    Vendor = "zilliz-byoc"
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          # 
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "zilliz_cse" {
  count = local.create_key ? 1 : 0

  name          = "alias/${var.prefix}-zilliz-cse"
  target_key_id = aws_kms_key.zilliz_cse[0].key_id
}

# IAM role for Zilliz cse cross-account access
resource "aws_iam_role" "zilliz_cse" {
  name = "${var.prefix}-zilliz-cse-role"

  tags = {
    Vendor = "zilliz-byoc"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = var.trust_role_arn
        }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.prefix
          }
        }
      }
    ]
  })
}

# Inline policy granting KMS encrypt/decrypt/describe on the cse key
resource "aws_iam_role_policy" "zilliz_cse_policy" {
  name = "${var.prefix}-zilliz-cse-policy"
  role = aws_iam_role.zilliz_cse.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = [
          local.cse_key_arn
        ]
      }
    ]
  })
}
