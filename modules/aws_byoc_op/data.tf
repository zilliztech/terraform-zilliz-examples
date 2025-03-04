data "aws_caller_identity" "current" {}

locals {
  config = yamldecode(file("${path.module}/conf.yaml"))
  // available zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  // auto-generate private subnets cidr
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 2, k)]
  public_subnets  = [cidrsubnet(cidrsubnet(var.vpc_cidr, 2, 3), 6, 62)]
  // security group ingress and egress rules
  sg_egress_ports     = [443]
  sg_ingress_protocol = ["tcp", "udp"]
  sg_egress_protocol  = ["tcp", "udp"]

  // eks output
  eks_oidc_url = replace(aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer, "https://", "")
  // bucket output
  bucket_id = module.s3_bucket["milvus"].s3_bucket_id

  // input parameters:
  vpc_cidr = var.vpc_cidr
  region       = var.aws_region
  
  dataplane_id = var.dataplane_id

  // node groups

  k8s_node_groups = var.k8s_node_groups

  account_id = data.aws_caller_identity.current.account_id

  
}
