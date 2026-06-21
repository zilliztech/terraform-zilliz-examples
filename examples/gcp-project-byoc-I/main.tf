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

  depends_on = [google_project_service.required]
}

module "gcs" {
  source = "../../modules/gcp_byoc_i/gcs"

  bucket_name   = local.bucket_name
  gcp_region    = local.gcp_region
  force_destroy = var.bucket_force_destroy
  labels        = local.common_labels

  depends_on = [google_project_service.required]
}

module "iam" {
  source = "../../modules/gcp_byoc_i/iam"

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

  depends_on = [google_project_service.required]
}

module "gke" {
  source = "../../modules/gcp_byoc_i/gke"

  gcp_project_id           = var.gcp_project_id
  gcp_region               = local.gcp_region
  gcp_zones                = local.gcp_zones
  cluster_name             = local.gke_cluster_name
  network_self_link        = module.vpc.vpc_self_link
  primary_subnet_self_link = module.vpc.primary_subnet_self_link
  pod_subnet_name          = module.vpc.pod_subnet_name
  service_subnet_name      = module.vpc.service_subnet_name
  gke_node_sa_email        = module.iam.gke_node_sa_email
  k8s_node_groups          = local.k8s_node_groups
  kubernetes_version       = var.kubernetes_version
  labels                   = local.common_labels
  master_authorized_networks = [
    {
      cidr_block   = module.vpc.primary_subnet_cidr
      display_name = "byoc-primary-subnet"
    }
  ]

  depends_on = [google_project_service.required, module.iam]
}

module "private_link" {
  count  = local.enable_private_link ? 1 : 0
  source = "../../modules/gcp_byoc_i/private-link"

  prefix_name           = local.prefix_name
  gcp_region            = local.gcp_region
  vpc_name              = module.vpc.vpc_name
  subnet_name           = module.vpc.primary_subnet_name
  service_attachment_id = var.gcp_psc_service_attachment_id

  depends_on = [google_project_service.required, module.vpc]
}

module "booter_vm" {
  source = "../../modules/gcp_byoc_i/booter-vm"

  prefix_name                  = local.prefix_name
  gcp_project_id               = var.gcp_project_id
  gcp_region                   = local.gcp_region
  gcp_zone                     = local.gcp_zones[0]
  subnet_self_link             = module.vpc.primary_subnet_self_link
  booter_service_account_email = module.iam.booter_sa_email
  booter_image                 = var.booter_image
  machine_type                 = var.booter_machine_type
  gke_cluster_name             = module.gke.cluster_name
  dataplane_id                 = local.data_plane_id
  agent_config                 = local.agent_config
  labels                       = local.common_labels

  depends_on = [google_project_service.required, module.gke, module.private_link]
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
      service_subnet_name = module.vpc.service_subnet_name
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
    module.iam,
    module.private_link,
    module.booter_vm,
  ]

  lifecycle {
    ignore_changes  = [data_plane_id, project_id, gcp, ext_config]
    prevent_destroy = true
  }
}
