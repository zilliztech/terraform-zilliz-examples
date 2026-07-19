locals {
  config                = yamldecode(file("${path.module}/../../conf.yaml"))
  service_attachment_id = var.service_attachment_id != "" ? var.service_attachment_id : try(local.config.GCP.private_service_connect.service_attachment_ids[var.gcp_region], "")
  private_dns_domain    = var.private_dns_domain != "" ? "${trimsuffix(var.private_dns_domain, ".")}." : ""
  private_dns_zone_name = var.private_dns_zone_name != "" ? var.private_dns_zone_name : substr("${var.prefix_name}-psc-dns", 0, 63)
}
