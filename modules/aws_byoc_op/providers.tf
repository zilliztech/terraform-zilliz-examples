terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.20.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Vendor    = "zilliz-byoc"
    }
  }
}
provider "kubernetes" {
  host                   = aws_eks_cluster.zilliz_byoc_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.zilliz_byoc_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.example.token
}

# https://registry.terraform.io/providers/hashicorp/helm/latest/docs#credentials-config
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.zilliz_byoc_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.zilliz_byoc_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.example.token

  }
}