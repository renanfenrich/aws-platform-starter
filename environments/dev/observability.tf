module "observability" {
  source = "../../modules/observability"

  name_prefix                   = local.name_prefix
  alb_arn_suffix                = module.alb.alb_arn_suffix
  target_group_arn_suffix       = module.alb.target_group_arn_suffix
  rds_instance_id               = module.rds.db_instance_id
  ecs_cluster_name              = local.platform_is_ecs ? module.ecs[0].cluster_name : ""
  ecs_service_name              = local.platform_is_ecs ? module.ecs[0].service_name : ""
  enable_ecs_cpu_alarm          = local.platform_is_ecs
  enable_ec2_cpu_alarm          = local.enable_ec2_cpu_alarm
  ec2_asg_name                  = local.ecs_ec2_enabled ? module.ecs_ec2_capacity[0].autoscaling_group_name : local.platform_is_eks ? module.eks[0].node_group_autoscaling_group_name : local.platform_is_k8s ? module.k8s_ec2_infra[0].worker_autoscaling_group_name : ""
  enable_alarms                 = var.enable_alarms
  alarm_sns_topic_arn           = var.alarm_sns_topic_arn
  alb_5xx_threshold             = var.alb_5xx_threshold
  alb_latency_p95_threshold     = var.alb_latency_p95_threshold
  alb_unhealthy_host_threshold  = var.alb_unhealthy_host_threshold
  rds_cpu_threshold             = var.rds_cpu_threshold
  rds_free_storage_threshold_gb = var.rds_free_storage_threshold_gb
  ecs_cpu_threshold             = var.ecs_cpu_threshold
  ecs_memory_threshold          = var.ecs_memory_threshold
  ec2_cpu_threshold             = var.ec2_cpu_threshold
  evaluation_periods            = var.alarm_evaluation_periods
  period_seconds                = var.alarm_period_seconds
  tags                          = local.tags
}
