output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
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
