# Validation checks using null_resource for older Terraform compatibility

resource "null_resource" "validate_security_groups" {
  # Trigger validation when any of the relevant variables change
  triggers = {
    customer_vpc_id                                    = var.customer_vpc_id
    customer_cluster_additional_security_group_ids     = join(",", var.customer_cluster_additional_security_group_ids)
    customer_node_security_group_ids                   = join(",", var.customer_node_security_group_ids)
    customer_private_link_security_group_ids           = join(",", var.customer_private_link_security_group_ids)
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ "${var.customer_vpc_id}" != "" ] && [ "${length(var.customer_cluster_additional_security_group_ids)}" -eq "0" ]; then
        echo "ERROR: customer_cluster_additional_security_group_ids cannot be empty when customer_vpc_id is provided."
        exit 1
      fi
    EOT
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ "${var.customer_vpc_id}" != "" ] && [ "${length(var.customer_node_security_group_ids)}" -eq "0" ]; then
        echo "ERROR: customer_node_security_group_ids cannot be empty when customer_vpc_id is provided."
        exit 1
      fi
    EOT
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ "${var.customer_vpc_id}" != "" ] && [ "${length(var.customer_private_link_security_group_ids)}" -eq "0" ]; then
        echo "ERROR: customer_private_link_security_group_ids cannot be empty when customer_vpc_id is provided."
        exit 1
      fi
    EOT
  }
}

resource "null_resource" "validate_customer_ecr" {
  triggers = {
    ecr_account_id = var.customer_ecr.ecr_account_id
    ecr_region     = var.customer_ecr.ecr_region
    ecr_prefix     = var.customer_ecr.ecr_prefix
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ "${var.customer_ecr.ecr_prefix}" = "" ] || [ "${var.customer_ecr.ecr_account_id}" = "" ] || [ "${var.customer_ecr.ecr_region}" = "" ]; then
        echo "ERROR: ECR prefix, account ID and region cannot be empty"
        exit 1
      fi
    EOT
  }
}