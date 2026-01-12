output "state_bucket_name" {
  description = "S3 bucket name for Terraform state."
  value       = aws_s3_bucket.state.id
}

output "kms_key_arn" {
  description = "KMS key ARN for state and bootstrap encryption."
  value       = aws_kms_key.state.arn
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
