output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "RDS endpoint."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}

output "db_security_group_id" {
  description = "Security group ID for the database."
  value       = aws_security_group.db.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS master user secret."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used by RDS."
  value       = aws_kms_key.db.arn
}
