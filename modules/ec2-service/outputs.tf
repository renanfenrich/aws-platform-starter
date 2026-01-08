output "autoscaling_group_name" {
  description = "Name of the Auto Scaling group."
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = aws_launch_template.this.id
}

output "instance_role_arn" {
  description = "ARN of the EC2 instance role."
  value       = aws_iam_role.instance.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for EC2 logs."
  value       = aws_cloudwatch_log_group.app.name
}
