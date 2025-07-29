
locals {
  prefix_name = var.prefix_name
  subnet_ids                   = var.subnet_ids
  customer_pod_subnet_ids      = var.customer_pod_subnet_ids
  eks_control_plane_subnet_ids = coalescelist(var.eks_control_plane_subnet_ids, var.subnet_ids)
  config                       = yamldecode(file("${path.module}/../../conf.yaml"))
  k8s_node_groups              = var.k8s_node_groups
  # Dataplane ID for resource naming
  dataplane_id      = var.dataplane_id
  security_group_id = var.security_group_id
  # VPC CIDR block
  eks_oidc_url            = replace(aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_role                = aws_iam_role.eks_role
  maintenance_role        = aws_iam_role.maintenance_role
  eks_addon_role          = aws_iam_role.eks_addon_role
  eks_cluster_oidc_issuer = aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer
  bucket_id               = var.s3_bucket_id

  // customized name
  eks_cluster_name      = length(var.customer_eks_cluster_name) > 0 ? var.customer_eks_cluster_name : "${local.prefix_name}-eks"
  eks_role_name         = length(var.customer_eks_role_name) > 0 ? var.customer_eks_role_name : "${local.prefix_name}-eks-role"
  eks_addon_role_name   = length(var.customer_eks_addon_role_name) > 0 ? var.customer_eks_addon_role_name : "${local.prefix_name}-addon-role"
  maintenance_role_name = length(var.customer_maintenance_role_name) > 0 ? var.customer_maintenance_role_name : "${local.prefix_name}-maintenance-role"
  storage_role_name     = length(var.customer_storage_role_name) > 0 ? var.customer_storage_role_name : "${local.prefix_name}-storage-role"

  # Security group ingress protocols
  # sg_ingress_protocol = ["tcp", "udp"]

  # # Security group egress protocols
  # sg_egress_protocol = ["tcp", "udp"]

  # # Security group egress ports for external access
  # sg_egress_ports = [443]
  # azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  account_id = data.aws_caller_identity.current.account_id
  // auto-generate private subnets cidr

  ecr_account_id = var.customer_ecr.ecr_account_id
  ecr_region     = var.customer_ecr.ecr_region
  ecr_prefix     = var.customer_ecr.ecr_prefix

  agent_config_json = jsonencode(var.agent_config)
  boot_config = {
    EKS_CLUSTER_NAME    = local.eks_cluster_name
    DATAPLANE_ID        = var.dataplane_id
    REGION              = var.region
    AGENT_CONFIG        = local.agent_config_json
    MAINTAINCE_ROLE     = local.maintenance_role.arn
    OP_CONFIG           = jsonencode(local.config)
    EXTERNAL_ID         = var.external_id
    enable_private_link = var.enable_private_link
    ecr                 = jsonencode(var.customer_ecr)
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

systemctl restart containerd

until ctr --namespace k8s.io images ls >/dev/null 2>&1; do
  echo "waiting for ctr to be ready"
  sleep 3
done

DEFAULT_TAG=$(aws ecr describe-images \
  --registry-id 965570967084 \
  --region ${var.region} \
  --repository-name zilliz-byoc/infra/byoc-booter \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

DEFAULT_ZILLIZ_BYOC_IMAGE=965570967084.dkr.ecr.${var.region}.amazonaws.com/zilliz-byoc/infra/byoc-booter:$DEFAULT_TAG

TAG=$(aws ecr describe-images \
  --registry-id ${local.ecr_account_id} \
  --region ${local.ecr_region} \
  --repository-name ${local.ecr_prefix}/infra/byoc-booter \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

if [[ -z "$TAG" || "$TAG" == "None" ]]; then
  ZILLIZ_BYOC_IMAGE=$DEFAULT_ZILLIZ_BYOC_IMAGE
else
  ZILLIZ_BYOC_IMAGE=${local.ecr_account_id}.dkr.ecr.${local.ecr_region}.amazonaws.com/${local.ecr_prefix}/infra/byoc-booter:$TAG
fi

ctr image pull --user AWS:$(aws ecr get-login-password --region ${var.region})  $ZILLIZ_BYOC_IMAGE
ctr run --rm --net-host --privileged --env BOOT_CONFIG='${local.boot_config_json}'  $ZILLIZ_BYOC_IMAGE zilliz-bootstrap
echo "zilliz init result $?"

--==MYBOUNDARY==--
  
  EOF
  )

  init_user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e
echo "zilliz init eni start"

systemctl restart containerd

until ctr --namespace k8s.io images ls >/dev/null 2>&1; do
  echo "waiting for ctr to be ready"
  sleep 3
done

DEFAULT_TAG=$(aws ecr describe-images \
  --registry-id 965570967084 \
  --region ${var.region} \
  --repository-name zilliz-byoc/infra/byoc-booter \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

DEFAULT_ZILLIZ_BYOC_IMAGE=965570967084.dkr.ecr.${var.region}.amazonaws.com/zilliz-byoc/infra/byoc-booter:$DEFAULT_TAG

TAG=$(aws ecr describe-images \
  --registry-id ${local.ecr_account_id} \
  --region ${local.ecr_region} \
  --repository-name ${local.ecr_prefix}/infra/byoc-booter \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

if [[ -z "$TAG" || "$TAG" == "None" ]]; then
  ZILLIZ_BYOC_IMAGE=$DEFAULT_ZILLIZ_BYOC_IMAGE
else
  ZILLIZ_BYOC_IMAGE=${local.ecr_account_id}.dkr.ecr.${local.ecr_region}.amazonaws.com/${local.ecr_prefix}/infra/byoc-booter:$TAG
fi

K8S_SG_ID=$(aws eks describe-cluster --name ${local.eks_cluster_name} --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)

# for each the subnets in var.customer_pod_subnet_ids to get the availability zone list
SUBNET_IDS='${join(" ", var.customer_pod_subnet_ids)}'
SUBNET_AZS=""
if [ -z "$SUBNET_IDS" ]; then
  echo "No pod subnets provided, exiting."
  exit 0
fi

for subnet_id in $SUBNET_IDS; do
  # Remove quotes if present
  subnet_id=$(echo $subnet_id | tr -d '"')
  # Get the availability zone for this subnet
  az=$(aws ec2 describe-subnets --subnet-ids $subnet_id --region '${var.region}' --query 'Subnets[0].AvailabilityZone' --output text)
  # Add to SUBNET_AZS string
  if [ -z "$SUBNET_AZS" ]; then
    SUBNET_AZS="$az"
  else
    SUBNET_AZS="$SUBNET_AZS $az"
  fi
done


ctr image pull --user AWS:$(aws ecr get-login-password --region ${var.region})  $ZILLIZ_BYOC_IMAGE
ctr run --rm --net-host --privileged --env BOOT_CONFIG='${local.boot_config_json}' --env IS_INIT=true --env POD_SUBNET_IDS="$SUBNET_IDS" --env K8S_SG_ID="$K8S_SG_ID" --env SUBNET_AZS="$SUBNET_AZS" $ZILLIZ_BYOC_IMAGE zilliz-bootstrap
echo "zilliz init eni result $?"

--==MYBOUNDARY==--
  
  EOF
  )
}
