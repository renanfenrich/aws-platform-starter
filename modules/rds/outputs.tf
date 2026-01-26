output "db_instance_id" {
  description = "RDS instance identifier."
  value       = local.db_instance_id
}

output "db_endpoint" {
  description = "RDS endpoint."
  value       = local.db_instance_address
}

output "db_port" {
  description = "RDS port."
  value       = local.db_instance_port
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

output "backup_plan_enabled" {
  description = "Whether AWS Backup is enabled for the database."
  value       = var.enable_backup_plan
}

output "backup_plan_id" {
  description = "AWS Backup plan ID (null when disabled)."
  value       = var.enable_backup_plan ? aws_backup_plan.rds[0].id : null
}

output "backup_vault_name" {
  description = "AWS Backup vault name (null when disabled)."
  value       = var.enable_backup_plan ? aws_backup_vault.rds[0].name : null
}

output "backup_vault_arn" {
  description = "AWS Backup vault ARN (null when disabled)."
  value       = var.enable_backup_plan ? aws_backup_vault.rds[0].arn : null
}

output "backup_copy_destination_vault_arn" {
  description = "Destination backup vault ARN for cross-region copy (null when not set)."
  value       = length(trimspace(var.backup_copy_destination_vault_arn)) > 0 ? var.backup_copy_destination_vault_arn : null
}
