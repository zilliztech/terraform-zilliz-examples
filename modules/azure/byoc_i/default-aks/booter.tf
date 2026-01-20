# Render agent template file with variables
# Always render template, use default empty values if agent_template_vars is not provided
locals {

  custom_data = base64encode(<<-EOF
#!/bin/bash
mdadm -Cv /dev/md0 -l0 -n2 /dev/nvme0n1 /dev/nvme1n1
mdadm -Ds > /etc/mdadm/mdadm.conf 
update-initramfs -u

mkfs.xfs /dev/md0
mkdir -p /var/lib/kubelet
echo '/dev/md0 /var/lib/kubelet xfs defaults 0 0' >> /etc/fstab
mount -a
echo 10485760 > /proc/sys/fs/aio-max-nr
EOF
  )

  agent_config = {
    repository          = "${local.azure_agent_config.acr_name}.azurecr.io/${local.azure_agent_config.acr_prefix}"
    tag                 = var.agent_tag != "" ? var.agent_tag : local.azure_agent_config.agent_tag
    serverHost          = "cloud-tunnel${local.host_suffix}"
    authToken           = var.auth_token
    dataPlaneId         = var.dataplane_id
    tunnelHost          = "k8s${local.dataplane_suffix}${local.host_suffix}"
    endpointIp          = ""
    maintenanceClientId = azurerm_user_assigned_identity.maintenance.client_id
  }
}

resource "local_file" "rendered_agent_valuesyaml" {
  filename = "${path.module}/agent-charts/agent.yaml"
  content = templatefile(
    "${path.module}/agent-charts/cloud_agent.tpl",
    local.agent_config
  )
}

data "azurerm_resources" "search_vmss" {
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group
  type                = "Microsoft.Compute/virtualMachineScaleSets"
  required_tags = {
    "search-vmss-id" = local.search_vmss_tag_value
  }
  depends_on = [azurerm_kubernetes_cluster_node_pool.search]
}

data "archive_file" "agent_context" {
  type       = "zip"
  source_dir = "${path.module}/agent-charts"

  output_path = "${path.module}/agent-context.zip"

  depends_on = [local_file.rendered_agent_valuesyaml]
}

resource "azapi_resource_action" "aks_run_command" {
  type        = "Microsoft.ContainerService/managedClusters@2025-10-01"
  resource_id = azurerm_kubernetes_cluster.main.id
  action      = "runCommand"
  method      = "POST"

  locks = [data.archive_file.agent_context.output_sha256]

  body = {
    command = <<-EOT
      helm upgrade --install cloud-agent ./ -f ./agent.yaml -n vdc --create-namespace
      kubectl rollout status deployment/cloud-agent -n vdc --timeout=50s
    EOT

    context = filebase64(data.archive_file.agent_context.output_path)

  }

  depends_on = [data.archive_file.agent_context, azurerm_kubernetes_cluster_node_pool.core]

  response_export_values = ["properties.exitCode", "properties.logs"]
  lifecycle {
    ignore_changes = [body, locks]
    postcondition {
      condition     = self.output.properties.exitCode == 0
      error_message = "AKS Run Command failed.\nLogs: ${self.output.properties.logs}"
    }
  }

  timeouts {
    create = "60s"
    update = "60s"
    delete = "60s"
  }
}

