resource "aws_iam_role" "eks_role" {
  count = var.minimal_roles.enabled ? 0 : 1
  name = local.eks_role_name

  tags = merge({
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
  }, var.custom_tags)
  
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks-nodegroup.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Sid" : "EKSClusterAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Sid" : "EKSNodeAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  count      = var.minimal_roles.enabled ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy_attachment" {
  count      = var.minimal_roles.enabled ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  count      = var.minimal_roles.enabled ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  count      = var.minimal_roles.enabled ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_policy_attachment" {
  count      = var.minimal_roles.enabled ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_assume" {
  count      = var.minimal_roles.enabled ? 0 : 1
  policy_arn = aws_iam_policy.node_assume_role_policy.arn
  role       = aws_iam_role.eks_role[0].name
}

resource "aws_iam_policy" "node_assume_role_policy" {
  name        = "${local.prefix_name}-AssumeSpecificRolePolicy"
  description = "Policy to allow assuming a specific role"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.maintenance_role.arn
      }
    ]
  })

  tags = {
    "Vendor" = "zilliz-byoc"
  }
}
