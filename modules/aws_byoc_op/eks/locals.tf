locals {
   subnet_ids = var.subnet_ids
    config = yamldecode(file("${path.module}/conf.yaml"))
      k8s_node_groups = var.k8s_node_groups
  # Dataplane ID for resource naming
  dataplane_id = var.dataplane_id
  security_group_id = var.security_group_id
  # VPC CIDR block
  eks_oidc_url = replace(aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_name = aws_eks_cluster.zilliz_byoc_cluster.name
  eks_role = aws_iam_role.eks_role
  maintaince_role = aws_iam_role.maintaince_role
  eks_addon_role = aws_iam_role.eks_addon_role
  eks_cluster_oidc_issuer = aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer
  bucket_id = var.s3_bucket_id
  # Security group ingress protocols
  # sg_ingress_protocol = ["tcp", "udp"]

  # # Security group egress protocols
  # sg_egress_protocol = ["tcp", "udp"]

  # # Security group egress ports for external access
  # sg_egress_ports = [443]
  # azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  account_id        = data.aws_caller_identity.current.account_id
  // auto-generate private subnets cidr

 agent_config_json = jsonencode(var.agent_config)
  boot_config = {
    EKS_CLUSTER_NAME = local.eks_cluster_name
    DATAPLANE_ID     = var.dataplane_id
    REGION           = var.aws_region
    AGENT_CONFIG     = local.agent_config_json
    MAINTAINCE_ROLE  = local.maintaince_role.arn
    OP_CONFIG = jsonencode(local.config)
    EXTERNAL_ID = var.external_id
    enable_private_link = var.enable_private_link
  }

  # security_group_id = module.my_vpc.security_group_id

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
