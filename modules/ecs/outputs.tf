output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "capacity_provider_strategy" {
  description = "Capacity provider strategy for the ECS service."
  value       = aws_ecs_service.this.capacity_provider_strategy
}

output "requires_compatibilities" {
  description = "Task definition compatibilities."
  value       = aws_ecs_task_definition.this.requires_compatibilities
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task role."
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for ECS logs."
  value       = aws_cloudwatch_log_group.ecs.name
}
