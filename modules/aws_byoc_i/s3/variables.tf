variable "prefix_name" {
  description = "Prefix name"
  type        = string
}
variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
}

variable "custom_tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "customer_bucket_name" {
  description = "Bucket name"
  type        = string
  default     = ""
}