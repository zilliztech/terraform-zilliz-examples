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
  region   = var.aws_region

  dataplane_id = var.dataplane_id

  // node groups

  k8s_node_groups = var.k8s_node_groups

  account_id        = data.aws_caller_identity.current.account_id
  agent_config_json = jsonencode(var.agent_config)

  boot_config = {
    EKS_CLUSTER_NAME = aws_eks_cluster.zilliz_byoc_cluster.name
    DATAPLANE_ID     = var.dataplane_id
    REGION           = var.aws_region
    AGENT_CONFIG     = local.agent_config_json
    MAINTAINCE_ROLE  = aws_iam_role.maintaince_role.arn
    OP_CONFIG = jsonencode(local.config)
    EXTERNAL_ID = var.external_id
    enable_private_link = var.enable_private_link
  }

  boot_config_json = jsonencode(local.boot_config)

  core_user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e
echo "zilliz init start"
TAG=$(aws ecr describe-images \
  --registry-id 965570967084 \
  --region us-west-2 \
  --repository-name zilliz-byoc/infra/byoc-booter \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

ZILLIZ_BYOC_IMAGE=965570967084.dkr.ecr.us-west-2.amazonaws.com/zilliz-byoc/infra/byoc-booter:$TAG

ctr image pull --user AWS:$(aws ecr get-login-password --region us-west-2)  $ZILLIZ_BYOC_IMAGE
ctr run --rm --net-host --privileged --env BOOT_CONFIG='${local.boot_config_json}'  $ZILLIZ_BYOC_IMAGE zilliz-bootstrap
echo "zilliz init result $?"

--==MYBOUNDARY==--
  
  EOF
  )

}
