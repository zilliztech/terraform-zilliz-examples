resource "kubernetes_namespace" "milvus_tool" {
  metadata {
    name = "milvus-tool"
  }

  depends_on = [ aws_eks_node_group.core ]

  timeouts {
    delete = "10s"
  }
}

resource "kubernetes_namespace" "infra" {
  metadata {
    name = "infra"
    labels = {
      "control-plane" = "controller-manager"
    }
  }

  depends_on = [ aws_eks_node_group.core, kubernetes_namespace.milvus_tool ]

  timeouts {
    delete = "10s"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [ aws_eks_node_group.core, kubernetes_namespace.milvus_tool ]

  timeouts {
    delete = "10s"
  }
}

resource "kubernetes_namespace" "vdc" {
  metadata {
    name = "vdc"
  }

  depends_on = [ aws_eks_node_group.core, kubernetes_namespace.milvus_tool ]

  timeouts {
    delete = "10s"
  }
}

resource "kubernetes_namespace" "cloud_terminal" {
  metadata {
    name = "cloud-terminal"
  }

  depends_on = [ aws_eks_node_group.core, kubernetes_namespace.milvus_tool ]
  timeouts {
    delete = "10s"
  }
}

resource "kubernetes_service_account_v1" "cluster_admin_sa" {
  metadata {
    name      = "cluster-admin-sa"
    namespace = "kube-system"
  }

  depends_on = [ aws_eks_node_group.core ]
}

resource "kubernetes_cluster_role_v1" "cluster_admin_role" {
  metadata {
    name = "cluster-admin-role"
  }

  rule {
    verbs     = ["*"]
    api_groups = ["*"]
    resources = ["*"]
  }

  rule {
    verbs           = ["*"]
    non_resource_urls = ["*"]
  }

  depends_on = [ aws_eks_node_group.core ]
}

resource "kubernetes_cluster_role_binding_v1" "cluster_admin_binding" {
  metadata {
    name = "cluster-admin-binding"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cluster-admin-sa"
    namespace = "kube-system"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "cloud-terminal"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role_v1.cluster_admin_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [ aws_eks_node_group.core, kubernetes_namespace.cloud_terminal ]
}

resource "kubernetes_secret_v1" "cluster_admin_sa_secret" {
  metadata {
    name      = "cluster-admin-sa-secret"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.cluster_admin_sa.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true

  depends_on = [ aws_eks_node_group.core, kubernetes_cluster_role_binding_v1.cluster_admin_binding ]
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name           = aws_eks_cluster.zilliz_byoc_cluster.name
    cluster_endpoint       = aws_eks_cluster.zilliz_byoc_cluster.endpoint
    cluster_ca_data       = aws_eks_cluster.zilliz_byoc_cluster.certificate_authority[0].data
    service_account_token = kubernetes_secret_v1.cluster_admin_sa_secret.data["token"]
  })
  filename = "${path.module}/kubeconfig"

  depends_on = [
    kubernetes_secret_v1.cluster_admin_sa_secret
  ]
} 