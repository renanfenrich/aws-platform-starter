output "vault_name" {
  description = "Name of the AWS Backup vault."
  value       = aws_backup_vault.this.name
}

output "vault_arn" {
  description = "ARN of the AWS Backup vault."
  value       = aws_backup_vault.this.arn
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt the backup vault."
  value       = aws_kms_key.vault.arn
}
