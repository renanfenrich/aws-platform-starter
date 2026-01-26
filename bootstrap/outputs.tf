output "state_bucket_name" {
  description = "S3 bucket name for Terraform state."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_replication_enabled" {
  description = "Whether state bucket replication is enabled."
  value       = var.enable_state_bucket_replication
}

output "replica_state_bucket_name" {
  description = "Replica S3 bucket name for Terraform state (null when disabled)."
  value       = var.enable_state_bucket_replication ? aws_s3_bucket.state_replica[0].id : null
}

output "replica_state_bucket_arn" {
  description = "Replica S3 bucket ARN for Terraform state (null when disabled)."
  value       = var.enable_state_bucket_replication ? aws_s3_bucket.state_replica[0].arn : null
}

output "kms_key_arn" {
  description = "KMS key ARN for state and bootstrap encryption."
  value       = aws_kms_key.state.arn
}

output "replica_kms_key_arn" {
  description = "KMS key ARN for the replica state bucket (null when disabled)."
  value       = var.enable_state_bucket_replication ? aws_kms_key.state_replica[0].arn : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for infrastructure notifications."
  value       = aws_sns_topic.infra_notifications.arn
}

output "alb_access_logs_bucket_name" {
  description = "S3 bucket name for ALB access logs."
  value       = aws_s3_bucket.alb_access_logs.id
}

output "alb_access_logs_bucket_arn" {
  description = "S3 bucket ARN for ALB access logs."
  value       = aws_s3_bucket.alb_access_logs.arn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN when created (null if not enabled)."
  value       = length(aws_acm_certificate.app) > 0 ? aws_acm_certificate.app[0].arn : null
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN when enabled (null if not enabled)."
  value       = try(aws_iam_openid_connect_provider.github_oidc[0].arn, null)
}

output "github_oidc_role_name" {
  description = "GitHub Actions OIDC role name when enabled (null if not enabled)."
  value       = try(aws_iam_role.github_oidc[0].name, null)
}

output "github_oidc_role_arn" {
  description = "GitHub Actions OIDC role ARN when enabled (null if not enabled)."
  value       = try(aws_iam_role.github_oidc[0].arn, null)
}
