output "example_service_name" {
  description = "Name of the example ECS service."
  value       = aws_ecs_service.example.name
}

output "example_task_definition_arn" {
  description = "ARN of the example task definition."
  value       = aws_ecs_task_definition.example.arn
}

output "alb_listener_arn" {
  description = "ALB listener ARN (HTTPS when enabled, otherwise HTTP)."
  value       = local.alb_listener_arn
}

output "target_group_arn" {
  description = "ALB target group ARN used by the example service."
  value       = data.terraform_remote_state.platform.outputs.target_group_arn
}

output "alb_health_check_path" {
  description = "Health check path read from the ALB target group."
  value       = local.health_check_path
}

output "container_image" {
  description = "Container image used by the example task definition."
  value       = local.container_image
}
