output "db_instance_id" {
  description = "RDS instance identifier."
  value       = var.prevent_destroy ? aws_db_instance.protected[0].id : aws_db_instance.this[0].id
}

output "db_endpoint" {
  description = "RDS endpoint."
  value       = var.prevent_destroy ? aws_db_instance.protected[0].address : aws_db_instance.this[0].address
}

output "db_port" {
  description = "RDS port."
  value       = var.prevent_destroy ? aws_db_instance.protected[0].port : aws_db_instance.this[0].port
}

output "db_security_group_id" {
  description = "Security group ID for the database."
  value       = aws_security_group.db.id
}

output "additional_ingress_security_group_ids" {
  description = "Additional security group IDs allowed to access the database."
  value       = var.additional_ingress_security_group_ids
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS master user secret."
  value       = var.prevent_destroy ? aws_db_instance.protected[0].master_user_secret[0].secret_arn : aws_db_instance.this[0].master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used by RDS."
  value       = local.kms_key_arn
}
