resource "aws_iam_role" "storage_role" {
  name = "zilliz-byoc-${var.name}-storage-role"
  tags = {
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }

  lifecycle {
    ignore_changes = [
      assume_role_policy
    ]
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${var.federated_principal}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "eks_oidc_url:aud" : "sts.amazonaws.com",
            "eks_oidc_url:sub" : [
              "system:serviceaccount:milvus-*:milvus*",
              "system:serviceaccount:loki:loki*",
              "system:serviceaccount:index-pool:milvus*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "storage_policy" {
  name        = "zilliz-byoc-${var.name}-storage-policy"
  description = "Policy for storage role"
  tags = {
    Vendor = "zilliz-byoc"
  }
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket"
        ],
        "Resource" : "arn:aws:s3:::${var.bucketName}"
      },
      {
        "Sid" : "AllowS3ReadWrite",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ],
        "Resource" : [
          "arn:aws:s3:::${var.bucketName}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
  policy_arn = aws_iam_policy.storage_policy.arn
  role       = aws_iam_role.storage_role.name
}

# https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html
resource "aws_iam_policy" "s3_kms_policy" {
  count       = var.enable_s3_kms ? 1 : 0
  name        = "zilliz-byoc-${var.name}-storage-kms-policy"
  description = "Policy for storage role KMS"
  tags = {
    Vendor = "zilliz-byoc"
  }
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        "Resource" : [var.s3_kms_key_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_kms_policy_attachment" {
  count      = var.enable_s3_kms ? 1 : 0
  policy_arn = aws_iam_policy.s3_kms_policy[0].arn
  role       = aws_iam_role.storage_role.name
} 