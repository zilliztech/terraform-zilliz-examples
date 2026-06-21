locals {
  config                = yamldecode(file("${path.module}/../../conf.yaml"))
  service_attachment_id = var.service_attachment_id != "" ? var.service_attachment_id : try(local.config.GCP.private_service_connect.service_attachment_ids[var.gcp_region], "")
}
