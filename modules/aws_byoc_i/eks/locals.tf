
locals {
  prefix_name = var.prefix_name
  subnet_ids                   = var.subnet_ids
  customer_pod_subnet_ids      = var.customer_pod_subnet_ids
  eks_control_plane_subnet_ids = coalescelist(var.eks_control_plane_subnet_ids, var.subnet_ids)
  config                       = yamldecode(file("${path.module}/../../conf.yaml"))
  k8s_node_groups              = var.k8s_node_groups
  # Dataplane ID for resource naming
  dataplane_id      = var.dataplane_id
  cluster_additional_security_group_ids = var.cluster_additional_security_group_ids
  node_security_group_ids = var.node_security_group_ids
  # VPC CIDR block
  eks_oidc_url            = replace(aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_role                = var.minimal_roles.enabled ? null : aws_iam_role.eks_role[0]
  maintenance_role        = aws_iam_role.maintenance_role
  eks_addon_role          = aws_iam_role.eks_addon_role
  
  # Minimal roles - simplified role references
  eks_cluster_role = var.minimal_roles.enabled ? (
    length(var.minimal_roles.cluster_role.use_existing_arn) > 0 ? data.aws_iam_role.external_cluster_role[0] : aws_iam_role.eks_cluster_role[0]
  ) : null
  
  eks_node_role = var.minimal_roles.enabled ? (
    length(var.minimal_roles.node_role.use_existing_arn) > 0 ? data.aws_iam_role.external_node_role[0] : aws_iam_role.eks_node_role[0]
  ) : null
  
  # Unified role selection for EKS resources
  # When minimal_roles is enabled, use dedicated roles; otherwise use the original unified role
  eks_cluster_role_arn = var.minimal_roles.enabled ? local.eks_cluster_role.arn : local.eks_role.arn
  eks_node_role_arn    = var.minimal_roles.enabled ? local.eks_node_role.arn : local.eks_role.arn
  eks_cluster_oidc_issuer = aws_eks_cluster.zilliz_byoc_cluster.identity[0].oidc[0].issuer
  bucket_id               = var.s3_bucket_id

  // customized name
  eks_cluster_name      = length(var.customer_eks_cluster_name) > 0 ? var.customer_eks_cluster_name : "${local.prefix_name}-eks"
  eks_role_name         = length(var.customer_eks_role_name) > 0 ? var.customer_eks_role_name : "${local.prefix_name}-eks-role"
  eks_addon_role_name   = length(var.customer_eks_addon_role_name) > 0 ? var.customer_eks_addon_role_name : "${local.prefix_name}-addon-role"
  maintenance_role_name = length(var.customer_maintenance_role_name) > 0 ? var.customer_maintenance_role_name : "${local.prefix_name}-maintenance-role"
  storage_role_name     = length(var.customer_storage_role_name) > 0 ? var.customer_storage_role_name : "${local.prefix_name}-storage-role"
  
  // Minimal roles naming (only used when enabled and creating new roles)
  minimal_cluster_role_name = var.minimal_roles.enabled && length(var.minimal_roles.cluster_role.use_existing_arn) == 0 ? (
    length(var.minimal_roles.cluster_role.name) > 0 ? var.minimal_roles.cluster_role.name : "${local.prefix_name}-eks-cluster-role"
  ) : "${local.prefix_name}-eks-cluster-role"  # fallback for resource creation
  
  minimal_node_role_name = var.minimal_roles.enabled && length(var.minimal_roles.node_role.use_existing_arn) == 0 ? (
    length(var.minimal_roles.node_role.name) > 0 ? var.minimal_roles.node_role.name : "${local.prefix_name}-eks-node-role"
  ) : "${local.prefix_name}-eks-node-role"  # fallback for resource creation

  eks_cluster_oidc_issuer_thumbprint = local.config.eks_cluster_oidc_issuer_thumbprint[var.region]

  # Security group ingress protocols
  # sg_ingress_protocol = ["tcp", "udp"]

  # # Security group egress protocols
  # sg_egress_protocol = ["tcp", "udp"]

  # # Security group egress ports for external access
  # sg_egress_ports = [443]
  # azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  account_id = data.aws_caller_identity.current.account_id
  // auto-generate private subnets cidr

  booter_ecr_account_id = length(var.booter.account_id) > 0 ? var.booter.account_id : var.customer_ecr.ecr_account_id
  booter_ecr_region     = length(var.booter.region) > 0 ? var.booter.region : (length(var.customer_ecr.ecr_region) > 0 ? var.customer_ecr.ecr_region : var.region)
  booter_ecr_prefix     = length(var.booter.prefix) > 0 ? var.booter.prefix : var.customer_ecr.ecr_prefix
  booter_ecr_image      = length(var.booter.image) > 0 ? var.booter.image : "infra/byoc-booter"


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
  --registry-id ${local.booter_ecr_account_id} \
  --region ${local.booter_ecr_region} \
  --repository-name ${local.booter_ecr_prefix}/${local.booter_ecr_image} \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

if [[ -z "$TAG" || "$TAG" == "None" || ${local.booter_ecr_account_id} == "965570967084" ]]; then
  # if the ecr account id is the zilliz's ecr account id, use the default image
  ZILLIZ_BYOC_IMAGE=$DEFAULT_ZILLIZ_BYOC_IMAGE
  ctr image pull --user AWS:$(aws ecr get-login-password --region ${var.region})  $ZILLIZ_BYOC_IMAGE
else
  ZILLIZ_BYOC_IMAGE=${local.booter_ecr_account_id}.dkr.ecr.${local.booter_ecr_region}.amazonaws.com/${local.booter_ecr_prefix}/${local.booter_ecr_image}:$TAG
  ctr image pull --user AWS:$(aws ecr get-login-password --region ${local.booter_ecr_region})  $ZILLIZ_BYOC_IMAGE
fi

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
set -ex
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
  --registry-id ${local.booter_ecr_account_id} \
  --region ${local.booter_ecr_region} \
  --repository-name ${local.booter_ecr_prefix}/${local.booter_ecr_image} \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

if [[ -z "$TAG" || "$TAG" == "None" ]]; then
  ZILLIZ_BYOC_IMAGE=$DEFAULT_ZILLIZ_BYOC_IMAGE
else
  ZILLIZ_BYOC_IMAGE=${local.booter_ecr_account_id}.dkr.ecr.${local.booter_ecr_region}.amazonaws.com/${local.booter_ecr_prefix}/${local.booter_ecr_image}:$TAG
fi

K8S_SG_ID="${aws_eks_cluster.zilliz_byoc_cluster.vpc_config[0].cluster_security_group_id}"

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