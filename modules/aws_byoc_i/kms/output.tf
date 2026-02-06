output "cse_key_arn" {
  description = "ARN of the KMS CMEK key (created or existing)"
  value       = local.cse_key_arn
}

output "cse_role_arn" {
  description = "ARN of the IAM role for cross-account CMEK access"
  value       = aws_iam_role.zilliz_cse.arn
}

output "external_id" {
  description = "External ID for the role"
  value       = var.prefix
}