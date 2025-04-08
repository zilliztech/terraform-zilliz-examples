variable "region" {
  description = "Region"
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