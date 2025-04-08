resource "aws_iam_role" "maintenance_role" {
  name = local.maintenance_role_name

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
              "system:serviceaccount:kube-system:cluster-admin-sa"
            ]
          }
        }
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : local.eks_role.arn
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : "${var.external_id}"
          }
        }
      }
    ]
  })

  tags = {
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }
}

resource "aws_iam_role_policy_attachment" "maintenance_policy_attachment_1" {
  policy_arn = aws_iam_policy.maintenance_policy_1.arn
  role       = aws_iam_role.maintenance_role.name
}

resource "aws_iam_role_policy_attachment" "maintenance_policy_attachment_2" {
  policy_arn = aws_iam_policy.maintenance_policy_2.arn
  role       = aws_iam_role.maintenance_role.name
}

resource "aws_iam_policy" "maintenance_policy_1" {
  name        = "${local.dataplane_id}-maintenance-policy-1"
  description = "cross account policy for the zilliz byoc (part 1)"
  tags = {
    Vendor = "zilliz-byoc"
  }
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCreateServiceLinkedRoleForEKS",
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : [
          "arn:aws:iam::*:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
          "arn:aws:iam::*:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup"
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "eks.amazonaws.com",
              "eks-nodegroup.amazonaws.com"
            ]
          }
        }
      },
      {
        "Sid" : "CreateOpenIDConnectProvider",
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider"
        ],
        "Resource" : [
          "arn:aws:iam::*:oidc-provider/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "DeleteOpenIDConnectProvider",
        "Effect" : "Allow",
        "Action" : [
          "iam:GetOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider"
        ],
        "Resource" : [
          "arn:aws:iam::*:oidc-provider/*"
        ]
      },
      {
        "Sid" : "IAMReadEKSRole",
        "Effect" : "Allow",
        "Action" : [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies"
        ],
        "Resource" : [
          "${local.eks_role.arn}",
          "arn:aws:iam::*:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup"
        ]
      },
      {
        "Sid" : "IAMPassRoleToEKS",
        "Effect" : "Allow",
        "Action" : [
          "iam:PassRole"
        ],
        "Resource" : [
          aws_iam_role.eks_role.arn
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : "eks.amazonaws.com"
          }
        }
      },
      {
        "Sid" : "EC2Create",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateLaunchTemplate",
          "ec2:RunInstances"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:launch-template/*",
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:network-interface/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "EC2Update",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:RunInstances"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:launch-template/*",
          "arn:aws:ec2:*:*:image/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:subnet/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "EC2RunInstanceOnImage",
        "Effect" : "Allow",
        "Action" : [
          "ec2:RunInstances"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:image/*"
        ]
      },
      {
        "Sid" : "EC2Tag",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:launch-template/*",
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:image/*",
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:subnet/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "EC2TagWithRequestTag",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:launch-template/*",
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:image/*",
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:subnet/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "EC2Read",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "maintenance_policy_2" {
  name        = "${local.dataplane_id}-maintenance-policy-2"
  description = "cross account policy for the zilliz byoc (part 2)"
  tags = {
    Vendor = "zilliz-byoc"
  }
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "EKSCreate",
        "Effect" : "Allow",
        "Action" : [
          "eks:CreateCluster",
          "eks:CreateNodegroup",
          "eks:CreateAddon",
          "eks:CreateAccessEntry",
          "eks:CreatePodIdentityAssociation"
        ],
        "Resource" : [
          "arn:aws:eks:*:*:cluster/${local.eks_cluster_name}",
          "arn:aws:eks:*:*:addon/${local.eks_cluster_name}/*/*",
          "arn:aws:eks:*:*:nodegroup/${local.eks_cluster_name}/zilliz*/*",
          "arn:aws:eks:*:*:podidentityassociation/${local.eks_cluster_name}/*",
          "arn:aws:eks:*:*:access-entry/${local.eks_cluster_name}/*/*/*/*",
          "arn:aws:eks:*:*:access-policy/${local.eks_cluster_name}/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "EKSUpdate",
        "Effect" : "Allow",
        "Action" : [
          "eks:AssociateAccessPolicy",
          "eks:UpdateAccessEntry",
          "eks:UpdateAddon",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:UpdateNodegroupConfig",
          "eks:UpdateNodegroupVersion",
          "eks:UpdatePodIdentityAssociation"
        ],
        "Resource" : [
          "arn:aws:eks:*:*:cluster/${local.eks_cluster_name}",
          "arn:aws:eks:*:*:addon/${local.eks_cluster_name}/*/*",
          "arn:aws:eks:*:*:nodegroup/${local.eks_cluster_name}/zilliz*/*",
          "arn:aws:eks:*:*:podidentityassociation/${local.eks_cluster_name}/*",
          "arn:aws:eks:*:*:access-entry/${local.eks_cluster_name}/*/*/*/*",
          "arn:aws:eks:*:*:access-policy/${local.eks_cluster_name}/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/Vendor" : "zilliz-byoc"
          }
        }
      },
      {
        "Sid" : "EKSTag",
        "Effect" : "Allow",
        "Action" : [
          "eks:TagResource"
        ],
        "Resource" : [
          "arn:aws:eks:*:*:cluster/${local.eks_cluster_name}",
          "arn:aws:eks:*:*:addon/${local.eks_cluster_name}/*/*",
          "arn:aws:eks:*:*:nodegroup/${local.eks_cluster_name}/zilliz*/*",
          "arn:aws:eks:*:*:podidentityassociation/${local.eks_cluster_name}/*",
          "arn:aws:eks:*:*:access-entry/${local.eks_cluster_name}/*/*/*/*"
        ]
      },
      {
        "Sid" : "EKSRead",
        "Effect" : "Allow",
        "Action" : [
          "eks:DescribeCluster",
          "eks:DescribeNodegroup",
          "eks:DescribeAccessEntry",
          "eks:DescribeAddon",
          "eks:DescribeAddonConfiguration",
          "eks:DescribeAddonVersions",
          "eks:DescribePodIdentityAssociation",
          "eks:DescribeUpdate",
          "eks:ListAccessEntries",
          "eks:ListAccessPolicies",
          "eks:ListAddons",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:ListPodIdentityAssociations",
          "eks:ListTagsForResource"
        ],
        "Resource" : [
          "arn:aws:eks:*:*:cluster/${local.eks_cluster_name}",
          "arn:aws:eks:*:*:addon/${local.eks_cluster_name}/*/*",
          "arn:aws:eks:*:*:nodegroup/${local.eks_cluster_name}/zilliz*/*",
          "arn:aws:eks:*:*:podidentityassociation/${local.eks_cluster_name}/*",
          "arn:aws:eks:*:*:access-entry/${local.eks_cluster_name}/*/*/*/*",
          "arn:aws:eks:*:*:access-policy/${local.eks_cluster_name}/*"
        ]
      },
      {
        "Sid" : "EkSDelete",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:eks:*:*:cluster/${local.eks_cluster_name}",
          "arn:aws:eks:*:*:addon/${local.eks_cluster_name}/*/*",
          "arn:aws:eks:*:*:nodegroup/${local.eks_cluster_name}/zilliz*/*",
          "arn:aws:eks:*:*:podidentityassociation/${local.eks_cluster_name}/*",
          "arn:aws:eks:*:*:access-entry/${local.eks_cluster_name}/*/*/*/*",
          "arn:aws:eks:*:*:access-policy/${local.eks_cluster_name}/*"
        ],
        "Action" : [
          "eks:DeleteAccessEntry",
          "eks:DeleteAddon",
          "eks:DeleteCluster",
          "eks:DeleteFargateProfile",
          "eks:DeleteNodegroup",
          "eks:DeletePodIdentityAssociation"
        ]
      },
      {
        "Sid" : "S3CheckBucketLocation",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation"
        ],
        "Resource" : "arn:aws:s3:::${local.bucket_id}"
      }
    ]
  })
}

