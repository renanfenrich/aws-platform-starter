output "platform" {
  description = "Selected platform for compute."
  value       = var.platform
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "alb_sg_id" {
  description = "ALB security group ID."
  value       = module.alb.alb_security_group_id
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = module.alb.target_group_arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.network.private_subnet_ids
}

output "compute_sg_id" {
  description = "Security group ID for compute."
  value       = local.platform_is_k8s ? module.k8s_ec2_infra[0].worker_security_group_id : aws_security_group.app[0].id
}

output "service_identifier" {
  description = "Compute service identifier (ECS service name when platform = ecs)."
  value       = local.platform_is_ecs ? module.ecs[0].service_name : null
}

output "ecs_cluster_name" {
  description = "ECS cluster name (platform = ecs only)."
  value       = local.platform_is_ecs ? module.ecs[0].cluster_name : null
}

output "ecs_service_name" {
  description = "ECS service name (platform = ecs only)."
  value       = local.platform_is_ecs ? module.ecs[0].service_name : null
}

output "k8s_control_plane_private_ip" {
  description = "Kubernetes control plane private IP (platform = k8s_self_managed only)."
  value       = local.platform_is_k8s ? module.k8s_ec2_infra[0].control_plane_private_ip : null
}

output "k8s_node_asg_name" {
  description = "Kubernetes worker Auto Scaling group name (platform = k8s_self_managed only)."
  value       = local.platform_is_k8s ? module.k8s_ec2_infra[0].worker_autoscaling_group_name : null
}

output "cluster_access_instructions" {
  description = "How to access the Kubernetes cluster when platform = k8s_self_managed."
  value = local.platform_is_k8s ? (
    var.k8s_enable_ssm ? <<-EOT
      aws ssm start-session --target ${module.k8s_ec2_infra[0].control_plane_instance_id} --region ${var.aws_region}
      sudo -i
      export KUBECONFIG=/etc/kubernetes/admin.conf
      kubectl get nodes
    EOT
    : "SSM access is disabled (k8s_enable_ssm = false). Provide a private access path to the control plane to use kubectl."
  ) : null
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
