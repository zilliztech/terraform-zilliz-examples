
# ==================================================================================================
# EKS (ELASTIC KUBERNETES SERVICE) INTERFACE ENDPOINT
#
# An interface endpoint for the EKS control plane.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "eks" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.eks"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = []
  tags = { Name = "eks-interface-endpoint" }
}

# ==================================================================================================
# EKS AUTH INTERFACE ENDPOINT
#
# Endpoint for the EKS authentication service.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "eks_auth" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.eks-auth"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "eks-auth-interface-endpoint" }
}

# ==================================================================================================
# ECR API INTERFACE ENDPOINT
#
# Endpoint for the ECR API.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "ecr-api-interface-endpoint" }
  
}

# ==================================================================================================
# ECR DKR INTERFACE ENDPOINT
#
# Endpoint for the ECR DKR.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "ecr-dkr-interface-endpoint" }
}

# ==================================================================================================
# AUTOSCALING INTERFACE ENDPOINT
#
# Endpoint for EC2 Auto Scaling services.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "autoscaling" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.autoscaling"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "autoscaling-interface-endpoint" }
}

# ==================================================================================================
# EC2 INTERFACE ENDPOINT
#
# Endpoint for the EC2 API.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "ec2-interface-endpoint" }
}

# ==================================================================================================
# STS (SECURITY TOKEN SERVICE) INTERFACE ENDPOINT
#
# Critical for authentication and assuming IAM roles, especially for EKS.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "sts-interface-endpoint" }
}

# ==================================================================================================
# ELB (ELASTIC LOAD BALANCING) INTERFACE ENDPOINT
#
# Endpoint for the Elastic Load Balancing API.
# --------------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "elb" {
  count = var.enable_endpoint ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.zilliz_byoc_security_group.id]
  tags = { Name = "elb-interface-endpoint" }
}


