variable "enabled" {
  type    = bool
  default = false
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "storage_service_account_email" {
  type        = string
  description = "Existing customer DataPlane workload GSA allowed to impersonate the dedicated CMEK GSA."
}

variable "key_name" {
  type        = string
  default     = ""
  description = "Existing regional CryptoKey resource name. Empty creates a symmetric key."
}

variable "protection_level" {
  type    = string
  default = "SOFTWARE"
  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.protection_level)
    error_message = "Milvus CMEK supports SOFTWARE or HSM for newly created symmetric keys."
  }
}
