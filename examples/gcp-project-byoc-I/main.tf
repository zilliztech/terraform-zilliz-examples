data "zillizcloud_byoc_i_project_settings" "this" {
  project_id    = var.project_id
  data_plane_id = var.dataplane_id
}

module "vpc" {
  source = "../../modules/gcp_byoc_i/vpc"

  prefix_name    = local.prefix_name
  gcp_region     = local.gcp_region
  vpc_name       = local.vpc_name
  vpc_cidr       = var.vpc_cidr
  primary_subnet = var.primary_subnet
  pod_subnet     = var.pod_subnet
  service_subnet = var.service_subnet
  lb_subnet      = var.lb_subnet
  labels         = local.common_labels

  gcp_project_id        = var.gcp_project_id
  network_project_id    = local.network_project_id
  vpc_mode              = var.vpc_mode
  subnet_mode           = var.subnet_mode
  lb_subnet_mode        = var.lb_subnet_mode
  create_cloud_nat      = var.create_cloud_nat
  create_firewall_rules = var.create_firewall_rules

  depends_on = [google_project_service.required]
}

module "gcs" {
  source = "../../modules/gcp_byoc_i/gcs"

  bucket_mode           = var.bucket_mode
  bucket_name           = local.bucket_name
  gcp_project_id        = var.gcp_project_id
  gcp_region            = local.gcp_region
  force_destroy         = var.bucket_force_destroy
  labels                = local.common_labels
  enable_gcs_kms        = var.enable_gcs_kms
  gcs_kms_key_name      = var.gcs_kms_key_name
  grant_gcs_kms_key_iam = var.grant_gcs_kms_key_iam
  kms_protection_level  = var.gcs_kms_protection_level

  depends_on = [google_project_service.required, terraform_data.bucket_input_validation]
}

module "iam" {
  source = "../../modules/gcp_byoc_i/iam"

  service_account_mode            = var.service_account_mode
  manage_iam                      = var.manage_iam
  gcp_project_id                  = var.gcp_project_id
  prefix_name                     = local.prefix_name
  gke_location                    = local.gcp_region
  gke_cluster_name                = local.gke_cluster_name
  storage_bucket_name             = module.gcs.bucket_id
  gke_node_service_account_name   = var.customer_gke_node_service_account_name
  management_service_account_name = var.customer_management_service_account_name
  storage_service_account_name    = var.customer_storage_service_account_name
  booter_service_account_name     = var.customer_booter_service_account_name
  enable_direct_mig_resize        = var.enable_direct_mig_resize
  booter_instance_name            = local.booter_vm_name
  booter_zone                     = local.gcp_zones[0]
  enable_resource_manager_tags    = var.enable_resource_manager_tags
  vendor_tag_key_id               = local.vendor_tag_key_id
  vendor_tag_value_id             = local.vendor_tag_value_id

  depends_on = [google_project_service.required, terraform_data.vendor_tag_input_validation]
}

module "gke" {
  source = "../../modules/gcp_byoc_i/gke"

  gke_mode                             = var.gke_mode
  gcp_project_id                       = var.gcp_project_id
  gcp_region                           = local.gcp_region
  gcp_zones                            = local.gcp_zones
  cluster_name                         = local.gke_cluster_name
  network_self_link                    = module.vpc.vpc_self_link
  primary_subnet_self_link             = module.vpc.primary_subnet_self_link
  pod_subnet_name                      = module.vpc.pod_subnet_name
  service_subnet_name                  = module.vpc.service_subnet_name
  gke_node_sa_email                    = module.iam.gke_node_sa_email
  k8s_node_groups                      = local.k8s_node_groups
  kubernetes_version                   = var.kubernetes_version
  master_ipv4_cidr_block               = var.master_ipv4_cidr_block
  enable_private_endpoint              = var.gke_enable_private_endpoint
  enable_private_nodes                 = var.gke_enable_private_nodes
  enable_ip_alias                      = var.gke_enable_ip_alias
  workload_pool                        = var.gke_workload_pool
  node_initial_count                   = var.gke_node_initial_count
  node_disk_size_gb                    = var.gke_node_disk_size_gb
  node_image_type                      = var.gke_node_image_type
  release_channel                      = upper(var.gke_release_channel)
  binary_authorization_evaluation_mode = upper(var.gke_binary_authorization_evaluation_mode)
  enable_identity_service              = var.gke_enable_identity_service
  enable_intranode_visibility          = var.gke_enable_intranode_visibility
  node_enable_secure_boot              = var.gke_node_enable_secure_boot
  node_enable_integrity_monitoring     = var.gke_node_enable_integrity_monitoring
  node_auto_repair                     = var.gke_node_auto_repair
  node_auto_upgrade                    = var.gke_node_auto_upgrade
  enable_secrets_encryption            = var.enable_gke_secrets_encryption
  secrets_kms_key_name                 = var.gke_secrets_kms_key_name
  kms_protection_level                 = var.gke_secrets_kms_protection_level
  grant_secrets_kms_key_iam            = var.grant_gke_secrets_kms_key_iam
  boot_disk_kms_key_name               = module.pd_kms.key_name
  node_group_local_ssd_counts          = var.gke_node_group_local_ssd_counts
  node_group_disk_overrides            = var.gke_node_group_disk_overrides
  labels                               = local.common_labels
  master_authorized_networks = [
    {
      cidr_block   = module.vpc.primary_subnet_cidr
      display_name = "byoc-primary-subnet"
    }
  ]

  depends_on = [google_project_service.required, terraform_data.gke_input_validation, module.iam, module.shared_vpc_iam]
}

# GKE creates the <gcp_project_id>.svc.id.goog Workload Identity pool implicitly with
# the first Workload Identity enabled cluster in the project, so these bindings must be
# applied after module.gke. module.gke depends on module.iam for the node service
# account, which is why they cannot live in module.iam.
module "workload_identity" {
  source = "../../modules/gcp_byoc_i/workload-identity"

  manage_iam                     = var.manage_iam
  gcp_project_id                 = var.gcp_project_id
  gcp_project_number             = data.google_project.this.number
  gke_location                   = module.gke.cluster_location
  gke_cluster_name               = module.gke.cluster_name
  storage_sa_name                = module.iam.storage_sa_name
  management_sa_name             = module.iam.management_sa_name
  storage_workload_identity_ksas = local.storage_workload_identity_ksas

  depends_on = [google_project_service.required, module.iam, module.gke]
}

module "shared_vpc_iam" {
  count  = local.is_shared_vpc && var.manage_shared_vpc_iam ? 1 : 0
  source = "../../modules/gcp_byoc_i/shared-vpc-iam"

  service_project_id  = var.gcp_project_id
  host_project_id     = local.network_project_id
  gcp_region          = local.gcp_region
  primary_subnet_name = module.vpc.primary_subnet_name

  depends_on = [google_project_service.required, module.vpc]
}

module "private_link" {
  count  = local.enable_private_link ? 1 : 0
  source = "../../modules/gcp_byoc_i/private-link"

  prefix_name              = local.prefix_name
  gcp_region               = local.gcp_region
  service_attachment_id    = local.gcp_psc_service_attachment_id
  enable_private_dns       = var.enable_private_dns
  private_dns_domain       = local.psc_private_dns_domain
  private_dns_record_names = local.psc_private_dns_record_names

  gcp_project_id     = var.gcp_project_id
  network_project_id = local.network_project_id
  vpc_self_link      = module.vpc.vpc_self_link
  subnet_self_link   = module.vpc.primary_subnet_self_link

  depends_on = [google_project_service.required, module.vpc]
}

module "booter_vm" {
  count  = data.zillizcloud_byoc_i_project_settings.this.agent_bootstrap_required ? 1 : 0
  source = "../../modules/gcp_byoc_i/booter-vm"

  prefix_name                     = local.prefix_name
  instance_name                   = local.booter_vm_name
  gcp_project_id                  = var.gcp_project_id
  gcp_region                      = local.gcp_region
  gcp_zone                        = local.gcp_zones[0]
  subnet_self_link                = module.vpc.primary_subnet_self_link
  booter_service_account_email    = module.iam.booter_sa_email
  booter_image                    = local.booter_image
  machine_type                    = var.booter_machine_type
  failure_self_delete_ttl_seconds = var.booter_failure_self_delete_ttl_seconds
  print_serial_logs_on_apply      = var.booter_print_serial_logs_on_apply
  gke_cluster_name                = module.gke.cluster_name
  dataplane_id                    = local.data_plane_id
  agent_config                    = local.agent_config
  labels                          = local.common_labels
  resource_manager_tags           = local.vendor_resource_manager_tags
  boot_disk_kms_key_name          = module.pd_kms.key_name

  depends_on = [google_project_service.required, terraform_data.vendor_tag_input_validation, module.iam, module.workload_identity, module.gke, module.private_link]
}

resource "zillizcloud_byoc_i_project_agent" "this" {
  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  depends_on = [module.booter_vm]
}

resource "zillizcloud_byoc_i_project" "this" {
  project_id    = local.project_id
  data_plane_id = local.data_plane_id

  gcp = {
    region     = data.zillizcloud_byoc_i_project_settings.this.region
    project_id = var.gcp_project_id

    network = {
      vpc_name            = module.vpc.vpc_name
      primary_subnet_name = module.vpc.primary_subnet_name
      pod_subnet_name     = module.vpc.pod_subnet_name
      service_subnet_name = local.service_subnet_api_name
      lb_subnet_name      = module.vpc.lb_subnet_name
      psc_endpoint_ip     = local.psc_endpoint_ip
    }

    identity = {
      gke_node_sa   = module.iam.gke_node_sa_email
      management_sa = module.iam.management_sa_email
      storage_sa    = module.iam.storage_sa_email
    }

    gke = {
      cluster_name = module.gke.cluster_name
      zones        = local.gcp_zones
    }

    storage = {
      bucket_id = module.gcs.bucket_id
    }
  }

  ext_config = base64encode(jsonencode(local.ext_config))

  depends_on = [
    zillizcloud_byoc_i_project_agent.this,
    module.gke,
    module.gcs,
    module.pd_kms,
    module.iam,
    module.workload_identity,
    module.private_link,
    module.booter_vm,
  ]

  lifecycle {
    ignore_changes  = [data_plane_id, project_id, gcp, ext_config]
    prevent_destroy = true
  }
}

module "pd_kms" {
  source = "../../modules/gcp_byoc_i/pd-kms"

  enabled              = var.enable_pd_kms
  key_name             = var.pd_kms_key_name
  grant_key_iam        = var.grant_pd_kms_key_iam
  kms_protection_level = var.pd_kms_protection_level
  project_id           = var.gcp_project_id
  region               = local.gcp_region
  name_prefix          = local.gke_cluster_name

  depends_on = [google_project_service.required]
}
