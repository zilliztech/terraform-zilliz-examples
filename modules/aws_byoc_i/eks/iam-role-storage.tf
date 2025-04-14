resource "aws_iam_role" "storage_role" {
  name = local.storage_role_name
  tags = merge({
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)

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
          "Federated": "arn:aws:iam::${local.account_id}:oidc-provider/${local.eks_oidc_url}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringLike" : {
            "${local.eks_oidc_url}:aud" : "sts.amazonaws.com",
            "${local.eks_oidc_url}:sub" : [
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
  name        = "${local.dataplane_id}-storage-policy"
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
        "Resource": "arn:aws:s3:::${local.bucket_id}"
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
          "arn:aws:s3:::${local.bucket_id}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
  policy_arn = aws_iam_policy.storage_policy.arn
  role       = aws_iam_role.storage_role.name
}
