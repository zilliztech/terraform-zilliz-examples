variable "enabled" {
  type    = bool
  default = true
}
variable "key_name" {
  type    = string
  default = ""
  validation {
    condition     = var.key_name == "" || can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.key_name))
    error_message = "key_name must be empty or a full Cloud KMS crypto key resource name."
  }
}
variable "grant_key_iam" {
  type    = bool
  default = true
}
variable "project_id" { type = string }
variable "region" { type = string }
variable "name_prefix" { type = string }
