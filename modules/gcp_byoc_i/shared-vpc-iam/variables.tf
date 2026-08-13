variable "service_project_id" {
  description = "GCP service project that owns the GKE cluster."
  type        = string
}

variable "host_project_id" {
  description = "Shared VPC host project."
  type        = string
}

variable "gcp_region" {
  description = "Region of the shared primary subnet."
  type        = string
}

variable "primary_subnet_name" {
  description = "Shared VPC subnet used by GKE."
  type        = string
}
