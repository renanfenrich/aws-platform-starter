output "alb_arn" {
  description = "ARN of the ALB."
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for CloudWatch dimensions)."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for CloudWatch dimensions)."
  value       = aws_lb_target_group.this.arn_suffix
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener."
  value       = aws_lb_listener.https.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener (if enabled)."
  value       = var.enable_http ? aws_lb_listener.http[0].arn : null
}

output "alb_access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (null if disabled)."
  value       = length(aws_lb.this.access_logs) > 0 ? aws_lb.this.access_logs[0].bucket : null
}
