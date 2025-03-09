
resource "helm_release" "bootstrap" {
    name = "${local.dataplane_id}-cloud-agent"
    chart = "${path.module}/cloud-agent"
    namespace = "vdc"

    set {
        name  = "config.tunnel.dataPlaneId"
        value = local.dataplane_id
    }

    set {
        name  = "config.tunnel.serverHost"
        value = local.config.agent_config.server_host
    }

    set {
        name  = "config.tunnel.authToken"
        # bug https://github.com/hashicorp/terraform-provider-helm/issues/1022
        # escape comma to work around helm issue
        value = "${replace(var.agent_config.auth_token, ",", "\\,")}"
    }

    set {
        name  = "config.tunnel.k8sToken"
        value = kubernetes_secret_v1.cluster_admin_sa_secret.data["token"]
    }

    set {
        name  = "image.repository"
        value = local.config.agent_config.repository
    }

    set {
        name  = "image.tag"
        value = var.agent_config.tag
    }

    depends_on = [ aws_eks_node_group.core, kubernetes_namespace.vdc ]
}