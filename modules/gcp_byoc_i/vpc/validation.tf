resource "terraform_data" "validation" {
  input = {
    vpc_mode       = var.vpc_mode
    subnet_mode    = var.subnet_mode
    lb_subnet_mode = var.lb_subnet_mode
  }

  lifecycle {
    precondition {
      condition     = var.network_project_id == var.gcp_project_id || var.vpc_mode == "existing"
      error_message = "Shared VPC mode requires vpc_mode = existing; the Shared VPC must already exist in the host project."
    }

    precondition {
      condition     = var.vpc_mode == "existing" || (var.subnet_mode == "create" && contains(["create", "disabled"], var.lb_subnet_mode))
      error_message = "A newly created VPC requires a Terraform-created primary subnet and either a created or disabled LB subnet."
    }

    precondition {
      condition     = var.vpc_mode == "create" || var.vpc_name != ""
      error_message = "vpc_name is required when vpc_mode = existing."
    }

    precondition {
      condition     = var.subnet_mode == "create" || var.primary_subnet.name != ""
      error_message = "primary_subnet.name is required when subnet_mode = existing."
    }

    precondition {
      condition     = var.subnet_mode == "create" || (var.pod_subnet.name != "" && (local.managed_services || var.service_subnet.name != ""))
      error_message = "pod_subnet.name and, unless gke-managed, service_subnet.name must identify existing secondary ranges when subnet_mode = existing."
    }

    precondition {
      condition     = var.subnet_mode == "create" || var.pod_subnet.name != var.service_subnet.name
      error_message = "pod_subnet.name and service_subnet.name must be different secondary ranges."
    }

    precondition {
      condition     = var.subnet_mode == "create" || (length(local.existing_pod_ranges) == 1 && (local.managed_services || length(local.existing_service_ranges) == 1))
      error_message = "The existing primary subnet must contain the Pod range and, unless gke-managed, the Service range."
    }

    precondition {
      condition     = var.subnet_mode == "create" || local.primary_subnet.network == local.vpc.self_link
      error_message = "The existing primary subnet does not belong to the selected VPC."
    }

    precondition {
      condition     = var.lb_subnet_mode == "existing" ? local.lb_subnet.network == local.vpc.self_link : true
      error_message = "The existing LB subnet must belong to the selected VPC."
    }

    precondition {
      condition     = var.lb_subnet_mode != "disabled" || (var.lb_subnet.name == "" && var.lb_subnet.cidr == "")
      error_message = "lb_subnet.name and lb_subnet.cidr must be empty when lb_subnet_mode is disabled."
    }
  }
}
