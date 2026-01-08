output "autoscaling_group_name" {
  description = "Auto Scaling group name for ECS capacity."
  value       = aws_autoscaling_group.this.name
}

output "capacity_provider_name" {
  description = "ECS capacity provider name."
  value       = aws_ecs_capacity_provider.this.name
}

output "instance_role_arn" {
  description = "IAM role ARN for ECS container instances."
  value       = aws_iam_role.instance.arn
}
