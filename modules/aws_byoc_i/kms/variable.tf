variable "trust_role_arn" {
  description = "The arn of the trust role"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.trust_role_arn))
    error_message = "trust_role_arn must be a valid IAM role ARN (e.g. arn:aws:iam::123456789012:role/MyRole)."
  }
}



variable "prefix" {
  description = "prefix of the resource name"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.prefix) > 0
    error_message = "prefix must not be empty."
  }
}


variable "aws_cse_exiting_key_arn" {
  description = "ARN of an existing KMS key to use. When set, no new key is created."
  type        = string
  nullable    = true
}