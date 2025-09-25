# Data source to check if external cluster role exists
data "aws_iam_role" "external_cluster_role" {
  count = var.minimal_roles.enabled && length(var.minimal_roles.cluster_role.use_existing_arn) > 0 ? 1 : 0
  name  = split("/", var.minimal_roles.cluster_role.use_existing_arn)[1]
}

# Data source to check if external node role exists
data "aws_iam_role" "external_node_role" {
  count = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) > 0 ? 1 : 0
  name  = split("/", var.minimal_roles.node_role.use_existing_arn)[1]
}

# EKS Cluster Role - Only for cluster management
resource "aws_iam_role" "eks_cluster_role" {
  count = var.minimal_roles.enabled && length(var.minimal_roles.cluster_role.use_existing_arn) == 0 ? 1 : 0
  name  = local.minimal_cluster_role_name

  tags = merge({
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
    RoleType = "cluster"
  }, var.custom_tags)
  
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "EKSClusterAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# EKS Node Role - Only for worker nodes
resource "aws_iam_role" "eks_node_role" {
  count = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) == 0 ? 1 : 0
  name  = local.minimal_node_role_name

  tags = merge({
    Vendor = "zilliz-byoc"
    Caller = data.aws_caller_identity.current.arn
    RoleType = "node"
  }, var.custom_tags)
  
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
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

# Policy attachments for EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_role_cluster_policy" {
  count      = var.minimal_roles.enabled && length(var.minimal_roles.cluster_role.use_existing_arn) == 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_vpc_policy" {
  count      = var.minimal_roles.enabled && length(var.minimal_roles.cluster_role.use_existing_arn) == 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role[0].name
}

# Policy attachments for EKS Node Role
resource "aws_iam_role_policy_attachment" "eks_node_role_cni_policy" {
  count      = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) == 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_node_role_ecr_policy" {
  count      = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) == 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_node_role_worker_policy" {
  count      = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) == 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role[0].name
}

# Assume role policy for node role
resource "aws_iam_role_policy_attachment" "eks_node_role_assume" {
  count      = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) == 0 ? 1 : 0
  policy_arn = aws_iam_policy.node_assume_role_policy.arn
  role       = aws_iam_role.eks_node_role[0].name
}
