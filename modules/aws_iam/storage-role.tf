resource "aws_iam_role" "storage_role" {
  name = "zilliz-byoc-${var.name}-storage-role"
  tags = {
    Vendor = "zilliz-byoc"
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
            "${var.eks_oidc_url}:aud" : "sts.amazonaws.com",
            "${var.eks_oidc_url}:sub" : [
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
