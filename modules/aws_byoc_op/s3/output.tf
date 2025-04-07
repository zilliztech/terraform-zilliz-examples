output "s3_bucket_id" {
  value = module.s3_bucket["milvus"].s3_bucket_id
}

# output "s3_bucket_arn" {
#   value = module.s3_bucket["milvus"].arn
# }