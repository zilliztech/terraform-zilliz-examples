locals {
    config = yamldecode(file("${path.module}/conf.yaml"))
}