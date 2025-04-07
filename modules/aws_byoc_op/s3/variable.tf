variable "region" {
  description = "Region"
  type        = string
}


variable "dataplane_id" {
  description = "Dataplane ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}


variable "route_table_ids" {
  description = "Route table IDs"
  type        = list(string)
}

