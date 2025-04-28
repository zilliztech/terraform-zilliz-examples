variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
  nullable    = false
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type    = string
  default = "us-west1"
  nullable    = false
}

variable "storage_bucket_name" {
  description = "The name of the GCS bucket."
  type        = string
  nullable    = false

  validation {
    condition     = var.storage_bucket_name != ""
    error_message = "variable storage_bucket_name cannot be empty."
  }
  
}