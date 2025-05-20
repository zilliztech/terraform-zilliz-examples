variable "gcp_project_id" {
  description = "The ID of the Google Cloud Platform project."
  type        = string
  nullable    = false
}

variable "gcp_region" {
  description = "The GCP region of the Google Cloud Platform project."
  type    = string
  nullable    = false
}

variable "gcp_vpc_name" {
  description = "The VPC name of the Google Cloud Platform project."
  type        = string
  nullable    = false
}

variable "service_subnet_name" {
  description = "The name of the service subnet."
  type        = string
  nullable    = false
}

variable "prefix_name" {
  description = "The prefix name of the resource."
  type        = string
  nullable    = false
}

