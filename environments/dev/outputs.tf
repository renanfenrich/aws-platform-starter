output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "alb_sg_id" {
  description = "ALB security group ID."
  value       = module.alb.alb_security_group_id
}

output "compute_sg_id" {
  description = "Security group ID for compute."
  value       = aws_security_group.app.id
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = module.alb.target_group_arn
}

output "service_identifier" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "rds_endpoint" {
  description = "RDS endpoint."
  value       = module.rds.db_endpoint
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN for the RDS master user."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}
