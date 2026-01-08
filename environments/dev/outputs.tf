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
  description = "Service identifier (ECS service name or EC2 ASG name)."
  value       = var.compute_mode == "ecs" ? module.ecs[0].service_name : module.ec2_service[0].autoscaling_group_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = var.compute_mode == "ecs" ? module.ecs[0].cluster_name : null
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = var.compute_mode == "ecs" ? module.ecs[0].service_name : null
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
