output "cross_account_role_arn" {
  value = aws_iam_role.cross_account_role.arn

}

output "external_id" {
  value = var.ExternalId
}

output "storage_role_arn" {
  value = aws_iam_role.storage_role.arn
  
}
