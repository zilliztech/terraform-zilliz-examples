project_id     = "proj-xxxxxxxx"
dataplane_id   = "zilliz-byoc-gcp-us-west1-xxxxxxxx"
gcp_project_id = "customer-gcp-project"

# Optional overrides.
# vpc_cidr = "10.0.0.0/16"
# Use a unique /28 when peering multiple BYOC-I VPCs.
# master_ipv4_cidr_block = "172.16.0.0/28"
# env = "Production"
# enable_private_link = true
# gcp_zones = ["us-west1-a", "us-west1-b", "us-west1-c"]
# Defaults to projects/vdc-dev-test/regions/<region>/serviceAttachments/zilliz-byoc-psc-dns when env = "UAT",
# otherwise projects/vdc-prod/regions/<region>/serviceAttachments/zilliz-byoc-psc-dns.
# gcp_psc_service_attachment_id = "projects/<producer-project>/regions/us-west1/serviceAttachments/<service-attachment>"
# enable_private_dns = true
# gcp_psc_private_dns_domain = "gcp-us-west1.byoc.cloud.zilliz.com."
# gcp_psc_private_dns_record_names = [
#   "cloud-tunnel.gcp-us-west1.byoc.cloud.zilliz.com.",
#   "cloud-open-api.gcp-us-west1.byoc.cloud.zilliz.com.",
# ]
# booter_failure_self_delete_ttl_seconds = 7200
# Print booter VM serial console logs during terraform apply. Requires gcloud on the Terraform runner.
# booter_print_serial_logs_on_apply = true
# Default resource names use zilliz-dp-<last-12-chars-of-dataplane_id>. Set these to keep existing names.
# customer_vpc_name = "zilliz-byoc-vpc"
# customer_gke_cluster_name = "zilliz-byoc-gke"
# customer_bucket_name = "zilliz-byoc-gcp-bucket"
# bucket_force_destroy = true
# Enable GCS bucket default encryption with a customer-managed Cloud KMS key.
# enable_gcs_kms = true
# gcs_kms_key_name = "projects/customer-gcp-project/locations/us-west1/keyRings/example-key-ring/cryptoKeys/example-key"
# Set to false only if the Cloud Storage service agent has already been granted KMS encrypter/decrypter permission.
# grant_gcs_kms_key_iam = true
# enable_resource_manager_tags = true
# Leave tag IDs empty to let Terraform create a per-dataplane tag.
# vendor_tag_key_id = "tagKeys/1234567890"
# vendor_tag_value_id = "tagValues/1234567890"
# Usually do not override these unless Zilliz instructs you to use custom tunnel hosts.
# agent_server_host = "cloud-tunnel.gcp-us-west1.byoc.cloud.zilliz.com"
# agent_tunnel_host = "k8sxxxxxxxx.gcp-us-west1.byoc.cloud.zilliz.com"
