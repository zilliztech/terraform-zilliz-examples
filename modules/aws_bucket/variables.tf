variable "aws_region" {
  description = "The region where zilliz operations will take place. Examples are us-east-1, us-west-2, etc."
  type        = string
}

variable "s3_bucket_names" {
  type = set(string)
  default = ["milvus"]
}

variable "name" {
  description = "The name of the byoc project"
  type        = string

}