locals {
  create_vendor_resource_manager_tag = var.enable_resource_manager_tags && var.vendor_tag_key_id == "" && var.vendor_tag_value_id == ""

  vendor_tag_key_id = (
    var.enable_resource_manager_tags
    ? (local.create_vendor_resource_manager_tag ? google_tags_tag_key.vendor[0].id : var.vendor_tag_key_id)
    : ""
  )
  vendor_tag_value_id = (
    var.enable_resource_manager_tags
    ? (local.create_vendor_resource_manager_tag ? google_tags_tag_value.zilliz_byoc[0].id : var.vendor_tag_value_id)
    : ""
  )
  vendor_resource_manager_tags = (
    var.enable_resource_manager_tags
    ? { (local.vendor_tag_key_id) = local.vendor_tag_value_id }
    : {}
  )
}

resource "terraform_data" "vendor_tag_input_validation" {
  input = var.enable_resource_manager_tags

  lifecycle {
    precondition {
      condition = (
        !var.enable_resource_manager_tags ||
        (var.vendor_tag_key_id == "" && var.vendor_tag_value_id == "") ||
        (var.vendor_tag_key_id != "" && var.vendor_tag_value_id != "")
      )
      error_message = "vendor_tag_key_id and vendor_tag_value_id must either both be empty or both be set when enable_resource_manager_tags is true."
    }
  }
}

resource "google_tags_tag_key" "vendor" {
  count = local.create_vendor_resource_manager_tag ? 1 : 0

  parent      = "projects/${var.gcp_project_id}"
  short_name  = "vendor"
  description = "Vendor tag key for Zilliz BYOC-I resources."

  depends_on = [google_project_service.required]
}

resource "google_tags_tag_value" "zilliz_byoc" {
  count = local.create_vendor_resource_manager_tag ? 1 : 0

  parent      = google_tags_tag_key.vendor[0].id
  short_name  = "zilliz-byoc"
  description = "Zilliz BYOC-I managed resource tag value."
}
